/* eslint-env browser */

// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import '../css/app.scss';

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
import 'phoenix_html';
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';

const EventEmitter = require('eventemitter3');

import Player from './player/Player';
import { COOKIE_TEST_TAKEN, COOKIE_TEST_AUTHOR } from './config/config';
import cookies from './utils/cookies';

const toClipboard = (text) => {
  navigator.clipboard.writeText(text);
};


const Hooks = {};

// ---------- TEST RESULT PAGE ----------

Hooks.TestResults = {
  mounted() {
    const testId = this.el.dataset.testid;
    let audio = null;

    // Send visitor test data to the result page
    if (localStorage[testId] !== undefined) {
      const results = JSON.parse(localStorage.getItem(testId));
      this.pushEvent('results', results);
    }

    // ensure the visitor has not already taken the test, otherwise report to the LV
    if (cookies.has(`${COOKIE_TEST_TAKEN}_${testId}`) === false
      && cookies.get(`${COOKIE_TEST_TAKEN}_${testId}`) !== 'true'
      && localStorage[`${testId}_taken`] === undefined
        &&  localStorage.getItem(`${testId}_taken`) !== 'true') {
      this.pushEvent("test_not_taken", {});
    }

    const play = (e) => {
      const { track_id, track_url } = e.detail;
      // pause currently playing track if any
      if (audio !== null) {
        audio.pause()
        audio = null;
      }
      audio = new Audio(track_url);
      audio.volume = 1;
      audio.play();

      this.pushEvent('playing', { track_id });
    };

    const stop = () => {
      if (audio !== null) {
        audio.pause()
        audio = null;
        this.pushEvent('stopping');
      }
    };

    window.addEventListener('play', play, false);
    window.addEventListener('stop', stop, false);
  },
  beforeDestroy() {
    window.removeEventListener('play', play, false);
    window.removeEventListener('stop', stop, false);
  }
};

// ---------- TEST PAGE ----------

Hooks.Test = {
  mounted() {
    const testId = this.el.dataset.testid;

    // ensure the visitor has not already taken the test, otherwise report to the LV
    if ((cookies.has(`${COOKIE_TEST_TAKEN}_${testId}`) &&
      cookies.get(`${COOKIE_TEST_TAKEN}_${testId}`) === 'true')
        || (localStorage[`${testId}_taken`] !== undefined
          &&  localStorage.getItem(`${testId}_taken`) === 'true')) {
      this.pushEvent("test_already_taken", {});
    }

    this.handleEvent('store_test', (params) => {
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}`, true);
      localStorage.setItem(testId, JSON.stringify(params));
      localStorage.setItem(`${testId}_taken`, true);
    });

    this.handleEvent('bypass_test', () => {
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}`, true);
      localStorage.setItem(`${testId}_taken`, true);
    });
  }
};

Hooks.Player = {
  mounted() {
    // ---------- INIT ----------

    const ee = new EventEmitter();

    const player = new Player(
      // init data from the html
      JSON.parse(this.el.dataset.tracks || '{}'),
      parseInt(this.el.dataset.rotateSeconds, 10) * 1000,
      this.el.dataset.rotate === 'true',
      this.el.dataset.loop === 'true',
      this.el.dataset.waveform === 'true',
      ee
    );

    const play = (e) => {
      const { track_hash, start_time} = e.detail;
      player.play(track_hash, start_time);
    };

    const stop = () => {
      player.stop();
    };

    const pause = () => {
      player.pause();
    };

    const back = () => {
      player.back();
    };

    window.addEventListener('play', play, false);
    window.addEventListener('stop', stop, false);
    window.addEventListener('pause', pause, false);
    window.addEventListener('back', back, false);

    document.addEventListener('keyup', (event) => {
      const key = event.key
      switch (key) {
        case " ":
          player.togglePlay(event.ctrlKey);
          break;

        case "ArrowDown":
        case "ArrowRight":
          player.goToNext(event.ctrlKey);
          break;

        case "ArrowUp":
        case "ArrowLeft":
          player.goToPrev(event.ctrlKey);
          break;

        default:
          let toDigit = Number.parseInt(key, 10);
          if (Number.isInteger(toDigit) && toDigit > 0) {
            if (event.shiftKey === true || event.altKey) {
              toDigit += 10;
            }
            player.goToTrack(toDigit, event.ctrlKey, event.shiftKey);
          }
      }
    });

    this.handleEvent('loop', (params) => {
      player.loop = params.loop === true;
    });

    this.handleEvent('rotate', (params) => {
      player.rotate = params.rotate === true;
      player.setRotate();
    });

    this.handleEvent('rotateSeconds', (params) => {
      player.rotateSeconds = params.seconds * 1000;
      player.setRotate();
    });

    // push events from other components
    ee.on('push_event', (params) => {
      const {event, data} = params;
      this.pushEvent(event, data);
    });

    this.handleEvent('tracks_loaded', () => {
      const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
      const popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl, {
          trigger: 'hover',
          // container: 'body'
        })
      });
    });
  },
  beforeDestroy() {
    window.removeEventListener('play', play, false);
    window.removeEventListener('stop', stop, false);
    window.removeEventListener('pause', pause, false);
    window.removeEventListener('back', back, false);
  }
  /* updated() {
    console.log("editor update...")
  } */
};

// ---------- TEST FORM PAGE ----------

Hooks.TestForm = {
  mounted() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl)
    })

    this.handleEvent('clipboard', (params) => {
      toClipboard(params.text);
    });

    this.handleEvent('saveTest', (params) => {
      if (params.test_author !== undefined && params.test_author !== null && params.test_author !== '') {
        cookies.set(COOKIE_TEST_AUTHOR, params.test_author);
      }

      // test if from a logged user
      if (params.test_password === undefined || params.test_password === null) {
        return;
      }

      cookies.set(`test_${params.test_id}`, params.test_password);
    });

    this.handleEvent('deleteTest', (params) => {
      // test if from a logged user
      if (params.test_password === undefined || params.test_password === null) {
        return;
      }

      cookies.remove(`test_${params.test_id}`);
    });
  }
};

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');
const liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks, params: { _csrf_token: csrfToken }
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', () => topbar.show());
window.addEventListener('phx:page-loading-stop', () => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug();
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
