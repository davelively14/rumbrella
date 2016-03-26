import Player from "./player"

let Video = {

  init(socket, element){ if(!element){ return }
    let playerId = element.getAttribute("data-player-id")
    let videoId  = element.getAttribute("data-id")
    socket.connect()
    Player.init(element.id, playerId, () => {

      // Runs after Player has loaded
      this.onReady(videoId, socket)
    })
  },

  // DOM element variables for our Video player:
  // msgContainer is for annotations
  // msgInput, postButton are both for creating a new annotation
  // vidChannel will connects our ES6 client to the Phoenix VideoChannel
  // The topics, which in this case are the videos, will need an identifier. We
  // take the form (conventionally) videos: + videoId. This lets us send events
  // easily to others interested in the same topic
  onReady(videoId, socket){
    let msgContainer = document.getElementById("msg-container")
    let msgInput     = document.getElementById("msg-input")
    let postButton   = document.getElementById("msg-submit")

    let vidChannel   = socket.channel("videos:" + videoId)

    // When user clicks the msg-submit element, we take the content of the
    // msg-input, send it to the server, then clear the msg-input control.
    postButton.addEventListener("click", e => {
      let payload = {body: msgInput.value, at: Player.getCurrentTime()}

      // This is the channels synchronous messaging. It's not truly synchronous,
      // but it does make readability easier. For every push of an event to the
      // server, we can optionally receive a response. Allows for request/
      // response style messaging over a socket connection.
      vidChannel.push("new_annotation", payload)
                .receive("error", e => console.log(e))
      msgInput.value = ""
    })

    msgContainer.addEventListener("click", e => {
      e.preventDefault()
      let seconds = e.target.getAttribute("data-seek") ||
                    e.target.parentNode.getAttribute("data-seek")
      if(!seconds){ return }

      Player.seekTo(seconds)
    })

    // Handles new events sent by the server and renders in the msg-container
    vidChannel.on("new_annotation", (resp) => {

      // Stores the last_seen_id in the channel's params object. Everytime we
      // this client sees a new annotation it will update
      vidChannel.params.last_seen_id = resp.id
      this.renderAnnotation(msgContainer, resp)
    })

    // On join, receives all the annotations, sends them to scheduleMessages to
    // be displayed
    vidChannel.join()
      .receive("ok", resp => {

        // Takes the max annotation ID and stores it as the last_seen_id
        let ids = resp.annotations.map(ann => ann.id)
        vidChannel.params.last_seen_id = Math.max(...ids)

        this.scheduleMessages(msgContainer, resp.annotations)
      })
      .receive("error", reason => console.log("join failed", reason))
    vidChannel.on("ping", ({count}) => console.log("PING", count))
  },

  // Something in here protects against cross-site scripting attacks? This
  // escapes user input. Will only return the string inside. I think I get it.
  esc(str){
    let div = document.createElement("div")
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  },

  renderAnnotation(msgContainer, {user, body, at}){
    let template = document.createElement("div")
    template.innerHTML = `
    <a href="#" data-seek="${this.esc(at)}">
      [${this.formatTime(at)}]
      <b>${this.esc(user.username)}</b>: ${this.esc(body)}
    </a>
    `
    msgContainer.appendChild(template)
    msgContainer.scrollTop = msgContainer.scrollHeight
  },

  // Starts an interval timer that will fire every second. Each time our timer
  // ticks, we call renderAtTime
  scheduleMessages(msgContainer, annotations){
    setTimeout(() => {
      let ctime = Player.getCurrentTime()
      let remaining = this.renderAtTime(annotations, ctime, msgContainer)
      this.scheduleMessages(msgContainer, remaining)
    }, 1000)
  },

  // Finds all annotations occuring at or before the current player time.
  renderAtTime(annotations, seconds, msgContainer){

    // Will render any annotations that were made at this point in the video
    // or earlier. Will return true on all remaining annotations so that our
    // scheduluer can keep tabs. Will return false on each annotaiton that is
    // rendered, which will exclude it from remaining sets.
    return annotations.filter( ann => {
      if(ann.at > seconds){
        return true
      } else {
        this.renderAnnotation(msgContainer, ann)
        return false
      }
    })
  },

  formatTime(at){
    let date = new Date(null)
    date.setSeconds(at / 1000)
    return date.toISOString().substr(14, 5)
  }
}
export default Video
