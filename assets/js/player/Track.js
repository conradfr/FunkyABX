/* eslint-env browser */

import Timeline from './Timeline';
import * as playerState from '../config/state';
import { CUE_OVER_TOLERANCE } from '../config/config'

export default class {
  constructor(src, drawWaveform, buffer, volume, ac, ee, initialState) {
    this.src = src;
    this.buffer = buffer;
    this.ac = ac;
    this.ee = ee;

    this.volume = volume;
    this.gainNode = null;
    this.active = false;
    this.source = null;

    this.lastPlayingStartedAt = null;
    this.pausedAt = null;
    this.startTime = null;
    this.currentSeconds = 0;
    this.lastPixel = null;

    // synced by player
    this.startCuePixel = null;
    this.endCuePixel = null;
    this.endCuePixelPreTolerance = null;
    this.endCuePixelPostTolerance = null;
    // Player can't know when a cue end is reached so we take the longest track and elect it to detect
    this.cueMaster = false;
    this.cueDetectorLock = null;
    this.startCueTime = null;

    this.tracksMaxDuration = null;
    this.sourceCtrl = null;
    this.waveform = null;
    this.drawWaveformUnder = drawWaveform;

    this.playerState = initialState;

    // Player state
    this.ee.on('player_state', (state) => {
      this.playerState = state;
      // this.refreshTimeline();
    });
  }

  // ---------- UTILS ----------

  setActive(active) {
    if (this.source !== null && this.gainNode !== null) {
      this.gainNode.gain.value = active ? this.volume : 0;
    }

    this.active = active;
    this.refreshTimeline();
  }

  setVolume(volume) {
    this.volume = volume;
    if (this.gainNode !== null && this.gainNode.gain) {
      this.gainNode.gain.value = this.active ? this.volume : 0;
    }
  }

  setStartCueTime() {
    // acting as a toggle
    if (this.startCuePixel) {
      this.startCuePixel = null;
      this.startCueTime = null;
    } else {
      const newStartPixel = this.getCurrentPixel();
      // not set if after cue end
      if (this.endCuePixel && this.endCuePixel < newStartPixel) {
        return;
      }

      this.startCueTime = this.cueMaster ? ((Date.now() - this.lastPlayingStartedAt) / 1000) + this.currentSeconds : null;
      this.startCuePixel = newStartPixel;
    }

    this.drawTimeline(true);
    if (this.cueMaster) {
      this.ee.emit('setCueStartTime', this.startCueTime);
    }
  }

  setEndCueTime(totalTracks) {
    // acting as a toggle
    // slight timeout helps to avoid the leader resetting the cue before other tracks set their marker
    setTimeout(() => {
      if (this.endCuePixel !== null) {
        this.endCuePixel = null;
        this.endCuePixelPreTolerance = null;
        this.endCuePixelPostTolerance = null;
      } else {
        const newEndPixel = this.getCurrentPixel();
        // not set if before cue start
        if (this.startCuePixel && this.startCuePixel > newEndPixel) {
          return;
        }

        this.endCuePixel = this.getCurrentPixel();
        this.endCuePixelPreTolerance = this.endCuePixel - CUE_OVER_TOLERANCE;
        this.endCuePixelPostTolerance = this.endCuePixel + CUE_OVER_TOLERANCE;
      }

      this.drawTimeline(true);
    }, this.cueMaster ? totalTracks * 1 : 0);
  }

  getDuration() {
    if (this.buffer === null) {
      return 0;
    }

    return this.buffer.duration;
  }

  cleanSource(fromEnding) {
    this.sourceCtrl = null;

    if (this.gainNode !== null) {
      this.gainNode.disconnect();
      this.gainNode = null;
    }

    if (this.source !== null) {
      this.source.disconnect();
      this.source = null;
      this.ee.emit('stopping', this.src.hash, fromEnding);
    }
  }

  setDrawWaveformUnder(drawWaveformUnder) {
    this.drawWaveformUnder = drawWaveformUnder;
    this.drawTimeline();
  }

  // ---------- PLAYBACK ----------

  play(startTime) {
    if (typeof startTime === 'boolean') {
      startTime = null;
    }

    if (startTime !== undefined && startTime !== null) {
      this.stop();
    }

    this.source = this.ac.createBufferSource();
    this.source.buffer = this.buffer;

    this.gainNode = this.ac.createGain();
    this.source.connect(this.gainNode);
    this.gainNode.connect(this.ac.destination);
    this.gainNode.gain.value = this.active ? this.volume : 0;

    this.sourceCtrl = Date.now();

    const sourcePromise = new Promise((resolve) => {
      const control = this.sourceCtrl;

      // keep track of the buffer state.
      this.source.onended = (e) => {
        // check that this event is from the current playback and not a previously stopped one
        if (this.source === null || control !== this.sourceCtrl) {
          e.preventDefault();
        } else {
          this.cleanSource(true);
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

  refreshTimeline() {
    this.drawTimeline(true);
  }

  drawTimeline(isRefresh) {
    // We get the canvas to get the dimensions as a canvas needs pixel dimensions

    // Container is needed to allow multiple round with id/hash changing
    const canvasContainer = document.getElementById(`waveform-${this.src.hash}`);
    if (canvasContainer === null) {
      return;
    }

    const canvasParentElem = canvasContainer.getElementsByClassName('waveform-wrapper')[0];
    if (canvasParentElem === null) {
      return;
    }

    let canvasElem = document.getElementById(`waveform-canvas-${this.src.hash}`);

    if (isRefresh !== true) {
      if (this.waveform !== null) {
        delete this.waveform;
        this.waveform = null;
      }

      if (canvasElem !== null) {
        canvasElem.remove();
        canvasElem = null;
      }
    }

    if (this.waveform === null) {
      if (canvasElem === null) {
        canvasElem = this.createCanvas(canvasParentElem);
      }

      this.createWaveform(canvasElem);
    }

    const currentPixel = this.getCurrentPixel();
    this.lastPixel = currentPixel !== null ? Math.round(currentPixel) : this.lastPixel || 0;
    this.waveform.draw(this.lastPixel, this.active, this.startCuePixel, this.endCuePixel);

    // CUE OVER DETECTION

    if (this.cueMaster === true && this.endCuePixel !== null
      && currentPixel >= this.endCuePixelPreTolerance && currentPixel < this.endCuePixelPostTolerance
      && !this.cueDetectorLock) {
      this.cueDetectorLock = true;
      this.ee.emit('cueIsOver', this.startCueTime);
    } else if (this.cueMaster === true && this.endCuePixel !== null
      && (currentPixel <= this.endCuePixelPreTolerance) || currentPixel >= this.endCuePixelPreTolerance) {
      this.cueDetectorLock = null;
    }
  }

  createCanvas(canvasParentElem) {
    const canvasElem = document.createElement('canvas');
    canvasElem.id = `waveform-canvas-${this.src.hash}`;
    canvasElem.dataset.hash = this.src.hash;
    canvasElem.style.width = `${canvasParentElem.offsetWidth}px`;
    canvasElem.style.height = `${canvasParentElem.offsetHeight}px`;
    canvasElem.width = canvasParentElem.offsetWidth;
    canvasElem.height = canvasParentElem.offsetHeight;
    canvasElem.className = 'waveform-canvas cursor-link';

    canvasElem.addEventListener('click', (e) => {
      /* eslint-disable max-len */
      const time = Math.floor(((e.clientX - e.target.getBoundingClientRect().x) * this.tracksMaxDuration) / e.target.width);
      this.ee.emit('waveformClick', { track_hash: e.target.dataset.hash, time });
    });

    canvasParentElem.appendChild(canvasElem);

    return canvasElem;
  }

  createWaveform(canvasElem) {
    // we give to the waveform drawer the length of the canvas relative to the other tracks
    const trackWidthPercent = this.tracksMaxDuration === this.getDuration()
      ? '100' : (this.getDuration() * 100) / this.tracksMaxDuration;

    /* eslint-disable max-len */
    this.waveform = new Timeline(canvasElem, this.drawWaveformUnder, this.buffer, trackWidthPercent);
  }

  // ---------- UTILS ----------

  getCurrentPixel() {
    // container is needed to allow multiple round with id/hash changing
    const canvasContainer = document.getElementById(`waveform-${this.src.hash}`);
    if (canvasContainer === null) {
      return;
    }

    const canvasParentElem = canvasContainer.getElementsByClassName('waveform-wrapper')[0];
    if (canvasParentElem === null) {
      return;
    }

    if (this.playerState === playerState.PLAYER_STOPPED) {
      return 0;
    } else if (this.source !== null && this.lastPlayingStartedAt !== null) {
      return ((((Date.now() - this.lastPlayingStartedAt) / 1000) + this.currentSeconds)
        * canvasParentElem.offsetWidth) / this.tracksMaxDuration;
    } else if (this.playerState === playerState.PLAYER_PLAYING) {
      // player is probably playing farther this track's duration.
      return canvasParentElem.offsetWidth;
    } else if (this.pausedAt !== null && this.currentSeconds !== null) {
      return (this.currentSeconds * canvasParentElem.offsetWidth) / this.tracksMaxDuration;
    } else if (this.pausedAt !== null && this.lastPlayingStartedAt !== null) {
      return ((((this.pausedAt - this.lastPlayingStartedAt) / 1000))
        * canvasParentElem.offsetWidth) / this.tracksMaxDuration;
    } else {
      return canvasParentElem.offsetWidth;
    } /* else {
      currentPixel = 0;
    } */
  }
}
