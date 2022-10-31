import EventEmitter from 'eventemitter3';
import cookies from '../utils/cookies';
import Player from '../player/Player';
import {COOKIE_TEST_WAVEFORM} from '../config/config';

let audioFiles = null;

const PlayerHook = {
  setAudioFiles(files) {
    audioFiles = files;
  },
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
}

export default PlayerHook;
