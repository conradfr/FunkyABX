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
import {Socket} from 'phoenix';
import {LiveSocket} from 'phoenix_live_view';
import topbar from '../vendor/topbar';
import {fileOpen, directoryOpen} from 'browser-fs-access';

const EventEmitter = require('eventemitter3');

import Player from './player/Player';
import {COOKIE_TEST_TAKEN, COOKIE_TEST_AUTHOR, COOKIE_TEST_WAVEFORM} from './config/config';
import cookies from './utils/cookies';

const toClipboard = (text) => {
  navigator.clipboard.writeText(text);
};

const audioFiles = {};

// TODO put each hook in its own file

const Hooks = {};

// ---------- MODAL ----------

Hooks.BsModal = {
  mounted() {
    this.modal = null;
    const id = this.el.dataset.id;

    this.open = () => {
      this.modal = new bootstrap.Modal(`#${id}`);
      this.modal.show();
    }

    this.close = () => {
      this.modal.hide();
    }

    window.addEventListener(`open_modal`, this.open);
    window.addEventListener(`close_modal`, this.close);

  },
  destroyed() {
    if (this.modal !== null) {
      this.modal.dispose();
    }

    window.removeEventListener('open_modal', this.open);
    window.removeEventListener('close_modal', this.close);
  }
}

// ---------- TEST RESULT PAGE ----------

Hooks.TestResults = {
  mounted() {
    const testId = this.el.dataset.testid;
    this.audio = null;

    // Send visitor test data to the result page
    if (localStorage[testId] !== undefined) {
      const results = JSON.parse(localStorage.getItem(testId));
      this.pushEvent('results', results);
    }

    if (localStorage[`${testId}_taken_session`] !== undefined) {
      this.pushEvent('session_id', localStorage[`${testId}_taken_session`]);
    } else if (cookies.has(`${COOKIE_TEST_TAKEN}_${testId}_session`) === true) {
      this.pushEvent('session_id', cookies.get(`${COOKIE_TEST_TAKEN}_${testId}_session`));
    }

    // ensure the visitor has not already taken the test, otherwise report to the LV
    if (cookies.has(`${COOKIE_TEST_TAKEN}_${testId}`) === false
      && cookies.get(`${COOKIE_TEST_TAKEN}_${testId}`) !== 'true'
      && localStorage[`${testId}_taken`] === undefined
      && localStorage.getItem(`${testId}_taken`) !== 'true') {
      this.pushEvent("test_not_taken", {});
    }

    this.play = async (e) => {
      const {test_local, track_id, track_url} = e.detail;
      // pause currently playing track if any
      if (this.audio !== null) {
        this.audio.pause();
        this.audio = null;
      }

      if (test_local === true) {
        const file = audioFiles[track_id];
        const fileUrl = URL.createObjectURL(file);

        this.audio = new Audio(fileUrl);
      } else {
        this.audio = new Audio(track_url);
      }

      this.audio.volume = 1;
      this.audio.play();

      this.pushEvent('playing', {track_id});
    };

    this.stop = () => {
      if (this.audio !== null) {
        this.audio.pause();
        this.audio = null;
        this.pushEvent('stopping');
      }
    };

    window.addEventListener('play', this.play, false);
    window.addEventListener('stop', this.stop, false);
  },
  destroyed() {
    this.stop();
    window.removeEventListener('play', this.play, false);
    window.removeEventListener('stop', this.stop, false);
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
        && localStorage.getItem(`${testId}_taken`) === 'true')) {
      this.pushEvent("test_already_taken", {});
    }

    this.handleEvent('store_test', (params) => {
      const {choices, session_id} = params;
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}`, true);
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}_session`, session_id);
      localStorage.setItem(testId, JSON.stringify(choices));
      localStorage.setItem(`${testId}_taken`, true);
      localStorage.setItem(`${testId}_taken_session_id`, session_id);
    });

    this.handleEvent('bypass_test', () => {
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}`, true);
      localStorage.setItem(`${testId}_taken`, true);
    });

    this.warningReload = (e) => {
      e.preventDefault();
      // the text is useless
      return 'Are you sure you want to leave/reload? Tracks will be lost.';
    }

    this.handleEvent('setWarningLocalTestReload', (params) => {
      if (params.set === false && this.preventReloadSet === true) {
        this.preventReloadSet = false;
        window.removeEventListener('beforeunload', this.warningReload);
        return;
      }

      if (params.set === true && this.preventReloadSet !== true) {
        this.preventReloadSet = true;
        window.addEventListener('beforeunload', this.warningReload);
      }
    });
  },
  destroyed() {
    if (this.preventReloadSet === true) {
      window.removeEventListener('beforeunload', this.warningReload);
    }
  }
};

Hooks.Player = {
  mounted() {
    // ---------- INIT ----------

    this.ee = new EventEmitter();

    const loadPlayer = (tracksJson) => {
      return new Player(
        // init data from the html
        JSON.parse(tracksJson || '{}'),
        parseInt(this.el.dataset.rotateSeconds, 10) * 1000,
        this.el.dataset.rotate === 'true',
        this.el.dataset.loop === 'true',
        this.el.dataset.waveform === 'true'
        && cookies.get(COOKIE_TEST_WAVEFORM, false) !== 'false',
        this.ee,
        audioFiles
      );
    }

    this.player = loadPlayer(this.el.dataset.tracks);

    // ---------- JS EVENTS ----------

    this.play = (e) => {
      const {track_hash, start_time} = e.detail;
      if (this.player !== null && this.player !== undefined) {
        this.player.play(track_hash, start_time);
      }
    };

    this.stop = () => {
      if (this.player !== null && this.player !== undefined) {
        this.player.stop();
      }
    };

    this.pause = () => {
      if (this.player !== null && this.player !== undefined) {
        this.player.pause();
      }
    };

    this.back = () => {
      if (this.player !== null && this.player !== undefined) {
        this.player.back();
      }
    };

    this.keyup = (event) => {
      if (this.player === null || this.player === undefined) {
        return;
      }

      const key = event.key
      switch (key) {
        case ' ':
          this.player.togglePlay(event.ctrlKey);
          break;

        case 'w':
          this.player.toggleDrawWaveform();
          break;

        case 'ArrowDown':
        case 'ArrowRight':
          this.player.goToNext(event.ctrlKey);
          break;

        case 'ArrowUp':
        case 'ArrowLeft':
          this.player.goToPrev(event.ctrlKey);
          break;

        default:
          let toDigit = Number.parseInt(key, 10);
          if (Number.isInteger(toDigit) && toDigit > 0) {
            if (event.shiftKey === true || event.altKey) {
              toDigit += 10;
            }
            this.player.goToTrack(toDigit, event.ctrlKey, event.shiftKey);
          }
      }
    }

    window.addEventListener('play', this.play, false);
    window.addEventListener('stop', this.stop, false);
    window.addEventListener('pause', this.pause, false);
    window.addEventListener('back', this.back, false);
    document.addEventListener('keyup', this.keyup, false);

    // push events from other components
    this.ee.on('push_event', (params) => {
      const {event, data} = params;
      this.pushEvent(event, data);
    });

    // ---------- SERVER EVENTS ----------

    this.handleEvent('loop', (params) => {
      if (this.player !== null && this.player !== undefined) {
        this.player.loop = params.loop === true;
      }
    });

    this.handleEvent('rotate', (params) => {
      if (this.player !== null && this.player !== undefined) {
        this.player.rotate = params.rotate === true;
        this.player.setRotate();
      }
    });

    this.handleEvent('rotateSeconds', (params) => {
      if (this.player !== null && this.player !== undefined) {
        this.player.rotateSeconds = params.seconds * 1000;
        this.player.setRotate();
      }
    });

    /* todo clean */
    this.handleEvent('update_tracks', (params) => {
      this.stop();
      this.pushEvent('stopping');
      this.player = null;

      this.ee.removeAllListeners('waveform-click');
      this.ee.removeAllListeners('playing');
      this.ee.removeAllListeners('stopping');
      this.ee.removeAllListeners('player_state');

      this.player = loadPlayer(params.tracks);
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
  destroyed() {
    this.stop();
    window.removeEventListener('play', this.play, false);
    window.removeEventListener('stop', this.stop, false);
    window.removeEventListener('pause', this.pause, false);
    window.removeEventListener('back', this.back, false);
    window.removeEventListener('keyup', this.back, false);
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
      if (params.test_access_key === undefined || params.test_access_key === null) {
        return;
      }

      cookies.set(`test_${params.test_id}`, params.test_access_key);
    });

    this.handleEvent('deleteTest', (params) => {
      // test if from a logged user
      if (params.test_access_key === undefined || params.test_access_key === null) {
        return;
      }

      cookies.remove(`test_${params.test_id}`);
    });

    this.handleEvent('store_params', ({params}) => {
      params.forEach((param) => {
        if (param.value !== null) {
          cookies.set(param.name, param.value);
        }
      })
    });
  }
};

// ---------- LOCAL TEST PAGE ----------

Hooks.LocalTestForm = {
  mounted() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl)
    })

    const isAllowedExt = (filename) => {
      const arr = filename.split(".");
      return ['wav', 'mp3', 'aac', 'flac'].indexOf(arr.pop()) !== -1;
    }

    this.handleEvent('store_params_and_redirect', ({url, params}) => {
      params.forEach((param) => {
        if (param.value !== null) {
          cookies.set(param.name, param.value);
        }
      });

      this.pushEvent('redirect', {url});
    });

    // ---------- DRAG & DROP ----------

    this.ondrop = async (event) => {
      event.preventDefault();

      for await (const item of event.dataTransfer.items) {
        if (item.kind === 'file') {
          const file = item.getAsFile();

          if (isAllowedExt(file.name)) {
            const id = self.crypto.randomUUID();
            audioFiles[id] = file;

            this.pushEvent('track_added', {id: id, filename: file.name});
          }
        }
      }
    };

    this.dropElem = document.getElementById('local_files_drop_zone');

    if (this.dropElem) {
      this.dropElem.addEventListener('drop', this.ondrop, false);
    }

    // ---------- FILE PICKER ----------

    this.fileButton = document.getElementById('local-file-picker');

    this.fileClick = async () => {
      const files = await fileOpen({
        mimeTypes: ['audio/*'],
        extensions: ['.wav', '.mp3', '.aac', '.flac'],
        multiple: true,
      });

      files.forEach(async file => {
        if (isAllowedExt(file.name)) {
          const id = self.crypto.randomUUID();
          audioFiles[id] = file;

          this.pushEvent('track_added', {id: id, filename: file.name});
        }
      });
    };

    this.fileButton.addEventListener('click', this.fileClick, false);

    // ---------- FOLDER PICKER ----------

    this.folderButton = document.getElementById('local-folder-picker');

    this.folderClick = async () => {
      const folder = await directoryOpen();

      folder.forEach(async file => {
        if (isAllowedExt(file.name)) {
          const id = self.crypto.randomUUID();
          audioFiles[id] = file;

          this.pushEvent('track_added', {id: id, filename: file.name});
        }
      });
    }

    this.folderButton.addEventListener('click', this.folderClick, false);
  },
  destroyed() {
    this.fileButton.removeEventListener('click', this.fileClick, false);
    this.folderButton.removeEventListener('click', this.folderClick, false);
    if (this.dropElem) {
      this.dropElem.removeEventListener('drop', this.ondrop, false);
    }
  }
};

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');
const liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks, params: {_csrf_token: csrfToken}
});

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: '#29d'}, shadowColor: 'rgba(0, 0, 0, .3)'});
window.addEventListener('phx:page-loading-start', () => topbar.show());
window.addEventListener('phx:page-loading-stop', () => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug();
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
