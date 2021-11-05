// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.scss"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import LoaderFactory from "./player/loader/LoaderFactory";
import Track from "./player/Track";
const EventEmitter = require('eventemitter3');
const drawBuffer = require('draw-wave');

let ac = null;
let ee = new EventEmitter();
let tracks = [];
let currentTrackIndex = 0;
let loop = null;
let rotate = null;
let rotateSeconds = null;
let rotateInterval = null;
let playing = 0;
let timeInterval = null;
let currentTime = 0;
let startTime = 0;
let maxDuration = 0;
let loopTimeout = null;

let Hooks = {}
Hooks.Player = {
  tracks() {
    return JSON.parse(this.el.dataset.tracks || "{}");
  },
  rotateSeconds() {
    return parseInt(this.el.dataset.rotateSeconds, 10) * 1000;
  },
  rotate() {
    return this.el.dataset.rotate === "true";
  },
  loop() {
    return this.el.dataset.loop === "true";
  },
  mounted() {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    ac = new AudioContext();
    const trackList = this.tracks();
    rotateSeconds = this.rotateSeconds();
    rotate = this.rotate();
    loop = this.loop();

    ee.on('playing', (track_hash) => {
      playing = playing + 1;
      if (playing === 1) {
        this.pushEvent('playing', {});
        startTime = ac.currentTime;
        currentTime = ac.currentTime;
        if (loop === true) {
          console.log('loop ?');
          console.log(currentTime);
          console.log(maxDuration);
          loopTimeout = setTimeout(() => {
            console.log('PLAY !!');
          }, maxDuration + 0.3);
        }
      }
    });

    ee.on('stopping', (track_hash) => {
      playing = playing - 1;
      if (playing === 0) {
        if (rotateInterval !== null) {
          console.log('cancel inter');
          clearInterval(rotateInterval);
        }
        this.pushEvent('stopping', {});
      }
    });

    const isPlaying = () => {
      return playing > 0;
    }

    const getNextTrackIndex = (from) => {
      let nextTrack = (from === undefined ? currentTrackIndex : from) + 1;
      if (nextTrack >= tracks.length) {
        nextTrack = 0;
      }

      return nextTrack;
    }

    const loadPromises = trackList.map((trackInfo) => {
      const loader = LoaderFactory.createLoader(
        trackInfo.url,
        ac,
        ee
      );
      return loader.load();
    });

    Promise.all(loadPromises)
      .then((audioBuffers) => {
          tracks = audioBuffers.map((audioBuffer, index) => {
            const track = new Track(trackList[index], audioBuffer, ac, ee);
            return track;
          });

          tracks = tracks.map((trackObj) => {
            drawBuffer.canvas(document.getElementById(`waveform-${trackObj.src.hash}`), trackObj.buffer, 'white');
            return trackObj;
          });

          const durations = tracks.map((trackObj) => {
            return trackObj.getDuration();
          });

          console.log(durations);

          maxDuration = Math.max(durations);
      });

    this.handleEvent('play', ({track_id, start}) => {
      const playoutPromises = [];
      tracks.forEach((track, index) => {
        track.setActive(index === currentTrackIndex);

        if (index === currentTrackIndex) {
          this.pushEvent('currentTrackHash', {track_hash: track.src.hash});
        }

        playoutPromises.push(
          track.schedulePlay()
        );
      });

      Promise.all(playoutPromises);

      if (rotate === true) {
        rotateInterval =
          setInterval(() => {
            let nextTrackIndex = null;
            let index = currentTrackIndex;
            do {
              nextTrackIndex = getNextTrackIndex(index);
              let nextTrack = tracks[nextTrackIndex];

              if (startTime + nextTrack.getDuration() < currentTime) {
                index = nextTrackIndex;
                nextTrackIndex = null;
              }
            } while (nextTrackIndex === null && index !== currentTrackIndex);

            if (nextTrackIndex === currentTrackIndex) {
              return;
            }

            currentTrackIndex = nextTrackIndex;

            tracks.forEach((track, index) => {
              track.setActive(index === nextTrackIndex);
              if (index === nextTrackIndex) {
                this.pushEvent('currentTrackHash', {track_hash: track.src.hash});
              }
            });
          }, rotateSeconds);
      }

      timeInterval =
        setInterval(() => {
          currentTime = ac.currentTime;
        }, 500);
    });

    this.handleEvent('stop', () => {
      if (rotateInterval !== null) {
        clearInterval(rotateInterval);
        rotateInterval = null;
      }

      tracks.forEach((track, index) => {
        track.stop();
      });

      this.playing = false;
    });

    this.handleEvent('loop', (params) => {
      loop = params.loop === "true";
    });

    this.handleEvent('rotate', (params) => {
      rotate = params.rotate === "true";
    });

    this.handleEvent('rotateSeconds', (params) => {
      rotateSeconds = params.seconds * 1000;
    });
  },
  updated() {
    console.log("editor update...")
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks, params: {_csrf_token: csrfToken}
})

const toClipboard = (text) => {
  alert('text');
}

const poute = () => {
  console.log('bonjour');
}

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
