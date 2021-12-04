/* eslint-env browser */

import Waveform from './Waveform';
import * as playerState from '../config/state';

// const drawBuffer = require('draw-wave');

export default class {
  constructor(src, buffer, ac, ee, initialState) {
    this.src = src;
    this.buffer = buffer;
    this.ac = ac;
    this.ee = ee;

    this.gainNode = null;
    this.active = false;
    this.source = null;

    this.lastPlayingStartedAt = null;
    this.pausedAt = null;
    this.startTime = null;
    this.currentSeconds = 0;
    this.lastPixel = null;

    this.tracksMaxDuration = null;
    this.sourceCtrl = null;
    this.waveform = null;

    this.playerState = initialState;

    // Player state
    this.ee.on('player_state', (state) => {
      this.playerState = state;
      // this.refreshWaveform();
    });
  }

  // ---------- UTILS ----------

  setActive(active) {
    if (this.source !== null && this.gainNode !== null) {
      this.gainNode.gain.value = active ? 1 : 0;
    }

    this.active = active;
  }

  getDuration() {
    if (this.buffer === null) {
      return 0;
    }

    return this.buffer.duration;
  }

  cleanSource() {
    this.sourceCtrl = null;

    if (this.gainNode !== null) {
      this.gainNode.disconnect();
      this.gainNode = null;
    }

    if (this.source !== null) {
      this.source.disconnect();
      this.source = null;
      this.ee.emit('stopping', this.src.hash);
    }
  }

  // ---------- PLAYBACK ----------

  play(startTime) {
    if (startTime !== undefined && startTime !== null) {
      this.stop();
    }

    this.source = this.ac.createBufferSource();
    this.source.buffer = this.buffer;

    this.gainNode = this.ac.createGain();
    this.source.connect(this.gainNode);
    this.gainNode.connect(this.ac.destination);
    this.gainNode.gain.value = this.active ? 1 : 0;

    this.sourceCtrl = Date.now();

    const sourcePromise = new Promise((resolve) => {
      const control = this.sourceCtrl;

      // keep track of the buffer state.
      this.source.onended = (e) => {
        // check that this event is from the current playback and not a previously stopped one
        if (this.source === null || control !== this.sourceCtrl) {
          e.preventDefault();
        } else {
          this.cleanSource();
        }
        resolve();
      };
    });

    this.lastPlayingStartedAt = Date.now();

    // player was paused and we restart at that time
    if (this.pausedAt && (startTime === undefined || startTime === null)) {
      this.startTime = this.currentSeconds;
      this.currentSeconds = this.startTime;
      this.pausedAt = null;

      this.source.start(0, this.startTime);
      this.ee.emit('playing', this.src.hash);
    } else {
      this.startTime = startTime || 0;
      this.currentSeconds = this.startTime;
      this.pausedAt = null;

      this.source.start(0, this.startTime);
      this.ee.emit('playing', this.src.hash);
    }

    return sourcePromise;
  }

  stop() {
    if (this.source !== null) {
      this.lastPlayingStartedAt = null;
      this.pausedAt = null;
      this.startTime = null;
      this.currentSeconds = 0;
      this.lastPixel = null;

      this.source.stop();
    }
    this.pausedAt = null;
    this.startTime = null;
    this.currentSeconds = 0;
    this.cleanSource();
  }

  pause() {
    if (this.source !== null) {
      this.pausedAt = Date.now();
      this.currentSeconds += (this.pausedAt - this.lastPlayingStartedAt) / 1000;
      this.source.stop();
    }
    this.cleanSource();
  }

  // ---------- WAVEFORM ----------

  refreshWaveform() {
    this.drawWaveform(true);
  }

  drawWaveform(isRefresh) {
    /*
      We get the canvas wrapper to get the dimensions, but we create the canvas in the body
      and not in the wrapper and position it in absolute to avoid LiveView refreshes
      that would destroy the canvas
   */

    const canvasParentElem = document.getElementById(`wrapper-waveform-${this.src.hash}`);
    let canvasElem = document.getElementById(`waveform-${this.src.hash}`);

    if (this.waveform === null) {
      if (canvasElem === null) {
        canvasElem = this.createCanvas(canvasParentElem);
      }

      this.createWaveform(canvasElem);
    }

    let currentPixel = null;

    if (this.playerState === playerState.PLAYER_STOPPED) {
      currentPixel = 0;
    } else if (this.source !== null && this.lastPlayingStartedAt !== null) {
      currentPixel = ((((Date.now() - this.lastPlayingStartedAt) / 1000) + this.currentSeconds)
                        * canvasParentElem.offsetWidth) / this.tracksMaxDuration;
    }
    // player is probably playing farther this track's duration.
    else if (this.playerState === playerState.PLAYER_PLAYING) {
      currentPixel = canvasParentElem.offsetWidth;
    } else if (this.pausedAt !== null && this.currentSeconds !== null) {
      currentPixel = (this.currentSeconds * canvasParentElem.offsetWidth) / this.tracksMaxDuration;
    } else if (this.pausedAt !== null && this.lastPlayingStartedAt !== null) {
      currentPixel = ((((this.pausedAt - this.lastPlayingStartedAt) / 1000))
        * canvasParentElem.offsetWidth) / this.tracksMaxDuration;
    } else {
        currentPixel = canvasParentElem.offsetWidth;
    } /* else {
      currentPixel = 0;
    } */

    if (currentPixel !== null && currentPixel === this.lastPixel) {
      // return;
    }

    this.lastPixel = currentPixel !== null ? currentPixel : this.lastPixel || 0;

    this.waveform.draw(this.lastPixel, this.active);
    // drawBuffer.canvas(canvasElem, trackObj.buffer, 'white');
  }

  createCanvas(canvasParentElem) {
    const canvasElem = document.createElement('canvas');
    canvasElem.id = `waveform-${this.src.hash}`;
    canvasElem.dataset.hash = this.src.hash;
    canvasElem.style.position = 'absolute';
    canvasElem.style.top = `${canvasParentElem.offsetTop}px`;
    canvasElem.style.left = `${canvasParentElem.offsetLeft}px`;
    canvasElem.style.width = `${canvasParentElem.offsetWidth}px`;
    canvasElem.style.height = `${canvasParentElem.offsetHeight}px`;
    canvasElem.width = canvasParentElem.offsetWidth;
    canvasElem.height = canvasParentElem.offsetHeight;
    canvasElem.className = 'waveform-canvas cursor-link';

    canvasElem.addEventListener('click', (e) => {
      const time = Math.floor((e.layerX * this.tracksMaxDuration) / e.target.width);
      this.ee.emit('waveform-click', { track_hash: e.target.dataset.hash, time });
    });

    const bodyElem = document.getElementsByTagName('body')[0];
    bodyElem.appendChild(canvasElem);

    return canvasElem;
  }

  createWaveform(canvasElem) {
    // we give to the waveform drawer the length of the canvas relative to the other tracks
    const trackWidthPercent = this.tracksMaxDuration === this.getDuration()
      ? '100' : (this.getDuration() * 100) / this.tracksMaxDuration;

    this.waveform = new Waveform(canvasElem, this.buffer, trackWidthPercent);
  }
}
