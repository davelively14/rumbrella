let Player = {
  player: null,

  init(domId, playerId, onReady){
    // Wire up to YouTube's special window.onYouTubeIframeAPIReady callback.
    window.onYouTubeIframeAPIReady = () => {
      this.onIframeReady(domId, playerId, onReady)
    }

    // Injects an iframe tag, which will trigger our event when ready
    let youtubeScriptTag = document.createElement("script")
    youtubeScriptTag.src = "//www.youtube.com/iframe_api"
    document.head.appendChild(youtubeScriptTag)
  },

  // This functino will create the player with the YouTube iframe API.
  onIframeReady(domId, playerId, onReady){
    this.player = new YT.Player(domId, {
      height: "360",
      width: "420",
      videoId: playerId, events: {
        "onReady": (event => onReady(event) ),
        "onStateChange": (event => this.onPlayerStateChange(event) )
      }
    })
  },

  // Convenience functions to send blind messages to a point in time for the
  // video playback.
  onPlayerStateChange(event){ },
  getCurrentTime(){ return Math.floor(this.player.getCurrentTime() * 1000) },
  seekTo(millsec){ return this.player.seekTo(millsec / 1000) }
}
export default Player
