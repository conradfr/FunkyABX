import EventEmitter from 'eventemitter3';
import cookies from '../utils/cookies';
import Player from '../player/Player';
import noUiSlider from 'nouislider';
import {
  COOKIE_TEST_WAVEFORM,
  COOKIE_TEST_ROTATE_SECONDS,
  COOKIE_VOLUME, COOKIE_DEVICE
} from '../config/config';

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
        cookies.get(COOKIE_VOLUME, 1),
        this.el.dataset.waveform === 'true'
        && cookies.get(COOKIE_TEST_WAVEFORM, false) !== 'false',
        this.ee,
        audioFiles
      );
    };

    if (cookies.has(COOKIE_TEST_ROTATE_SECONDS)) {
      this.pushEventTo(this.el, 'update_rotate_seconds', { seconds: cookies.get(COOKIE_TEST_ROTATE_SECONDS) });
    }

    this.player = loadPlayer(this.el.dataset.tracks);

    const slider = document.getElementById('volume-slider');
    noUiSlider.create(slider, {
      start: cookies.get(COOKIE_VOLUME, 1) * 100,
      connect: 'lower',
      range: {
        'min': 0,
        'max': 100
      }
    });

    slider.noUiSlider.on('set.one', (e) => {
      const volume = (e[0] / 100).toFixed(2);
      cookies.set(COOKIE_VOLUME, volume);
      if (this.player) {
        this.player.setVolume(volume);
      }
    });

    if ('setSinkId' in AudioContext.prototype) {
      this.pushEventTo(this.el, 'output_selector_detected', {});

      if (sessionStorage.getItem(COOKIE_DEVICE)) {
        try {
          // if current session has device saved, we simulate select option click to set it
          this.pushEventTo(
            this.el,
            'change_player_settings',
            {'_target': ['output-select'], 'output-select': cookies.get(COOKIE_DEVICE)}
          );
        } catch(e) {
          console.log(e.message);
        }
      }
    }

    // ---------- JS EVENTS ----------

    this.play = async (event) => {
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

    // NOTE we use cue instead of loop in the project to avoid naming confusion with the player loop option

    this.startCue = async (event) => {
      if (this.player === null || this.player === undefined) {
        return;
      }

      await this.player.setStartCue();
    };

    this.endCue = async (event) => {
      if (this.player === null || this.player === undefined) {
        return;
      }

      await this.player.setEndCue();
    };

    window.addEventListener('play', this.play, false);
    window.addEventListener('stop', this.stop, false);
    window.addEventListener('pause', this.pause, false);
    window.addEventListener('back', this.back, false);
    window.addEventListener('keyup', this.keyup, false);
    window.addEventListener('keydown', this.keydown, false);
    window.addEventListener('start_cue', this.startCue, false);
    window.addEventListener('end_cue', this.endCue, false);

    // push events from other components
    this.ee.on('push_event', (params) => {
      const { event, data } = params;
      this.pushEventTo(this.el, event, data);
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
      this.pushEventTo(this.el, 'stopping');
      this.player = null;

      this.ee.removeAllListeners('waveformClick');
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

    this.handleEvent('output_device_selected', (params) => {
      if (this.player !== null && this.player !== undefined) {
        this.player.setOutputDevice(params.device_id);
      }
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
    window.removeEventListener('start_cue', this.startCue, false);
    window.removeEventListener('end_cue', this.endCue, false);
  }
  /* updated() {
    console.log("editor update...")
  } */
};

export default PlayerHook;
