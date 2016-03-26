// ES6 imports the Socket object
import {Socket} from "phoenix"

// Phoenix instatiates a new Socket at our endpoint. The logger callback is
// optiona, but will include helpful debugging in the JS console.
let socket = new Socket("/socket", {
  params: {token: window.userToken},

  // Note: those are ` (tilde key apostraphe), not ' (quotation key)
  logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data) }
})

export default socket
