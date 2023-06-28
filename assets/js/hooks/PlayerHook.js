import EventEmitter from 'eventemitter3';
import cookies from '../utils/cookies';
import Player from '../player/Player';
import { COOKIE_TEST_WAVEFORM, COOKIE_TEST_ROTATE_SECONDS } from '../config/config';

let audioFiles = null;

/* eslint-disable no-undef */
const PlayerHook = {
  setAudioFiles(files) {
    audioFiles = files;
  },
  mounted() {
    // ---------- INIT ----------

    this.ee = new EventEmitter();
    this.ctrlPressed = false;

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
    };

    if (cookies.has(COOKIE_TEST_ROTATE_SECONDS)) {
      this.pushEvent('update_rotate_seconds', { seconds: cookies.get(COOKIE_TEST_ROTATE_SECONDS) });
    }

    this.player = loadPlayer(this.el.dataset.tracks);

    // ---------- JS EVENTS ----------

    this.play = (event) => {
      const { track_hash } = event.detail;

      if (this.ctrlPressed === true) {
        this.stop();
      }

      if (this.player !== null && this.player !== undefined) {
        this.player.play(track_hash);
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

    this.keydown = (event) => {
      if (this.player === null || this.player === undefined) {
        return;
      }

      const key = event.key;
      switch (key) {
        case 'Control':
          this.ctrlPressed = true;
          break;

        default:
          break;
      }
    };

    this.keyup = (event) => {
      if (this.player === null || this.player === undefined) {
        return;
      }

      const key = event.key;
      switch (key) {
        case 'Control':
          this.ctrlPressed = false;
          break;

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
    };

    window.addEventListener('play', this.play, false);
    window.addEventListener('stop', this.stop, false);
    window.addEventListener('pause', this.pause, false);
    window.addEventListener('back', this.back, false);
    window.addEventListener('keyup', this.keyup, false);
    window.addEventListener('keydown', this.keydown, false);

    // push events from other components
    this.ee.on('push_event', (params) => {
      const { event, data } = params;
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

    this.handleEvent('rotate_seconds', (params) => {
      if (this.player !== null && this.player !== undefined) {
        this.player.rotateSeconds = params.seconds * 1000;
        this.player.setRotate();
        cookies.set(COOKIE_TEST_ROTATE_SECONDS, params.seconds);
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
      const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
      popoverTriggerList.map((popoverTriggerEl) => {
        return new bootstrap.Popover(popoverTriggerEl, {
          trigger: 'hover',
          // container: 'body'
        });
      });
    });
  },
  destroyed() {
    this.stop();
    window.removeEventListener('play', this.play, false);
    window.removeEventListener('stop', this.stop, false);
    window.removeEventListener('pause', this.pause, false);
    window.removeEventListener('back', this.back, false);
    window.removeEventListener('keyup', this.keyup, false);
    window.removeEventListener('keydown', this.keydown, false);
  }
  /* updated() {
    console.log("editor update...")
  } */
};

export default PlayerHook;
