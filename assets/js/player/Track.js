/* eslint-env browser */

import Timeline from './Timeline';
import * as playerState from '../config/state';
import {
  CUE_DRAG_THRESHOLD_PX,
  CUE_EDGE_GRAB_PX,
  CUE_MIN_DURATION_SECONDS
} from '../config/config';

// Loudness normalization: a constant gain bringing the track to the common target loudness set by the player.
// The true peak of a track must stay below this max, which limits how loud it can be made.
const NORMALIZATION_MAX_TRUE_PEAK = -1;

export default class {
  constructor(src, drawWaveform, buffer, volume, normalization, ac, ee, initialState) {
    this.src = src;
    this.buffer = buffer;
    this.ac = ac;
    this.ee = ee;

    this.volume = volume;
    this.normalization = normalization;
    // set by player, common to all tracks
    this.normalizationTarget = null;
    this.normalizationGain = 1;
    this.gainNode = null;
    this.active = false;
    this.source = null;

    this.lastPlayingStartedAt = null;
    this.pausedAt = null;
    this.startTime = null;
    this.currentSeconds = 0;
    this.lastPixel = null;

    // cue (seconds), owned by the player and synced here only to be drawn (can be a drag preview)
    this.cueStart = null;
    this.cueEnd = null;
    // pointer interaction in progress on the canvas (seek click or cue drag)
    this.drag = null;

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
    this.active = active;
    if (this.source !== null) {
      this.applyGain();
    }

    this.refreshTimeline();
  }

  setVolume(volume) {
    this.volume = volume;
    this.applyGain();
  }

  setNormalization(normalization) {
    this.normalization = normalization;
    this.applyGain();
  }

  setNormalizationTarget(target) {
    this.normalizationTarget = target;
    this.normalizationGain = this.computeNormalizationGain();
    this.applyGain();
  }

  applyGain() {
    if (this.gainNode !== null && this.gainNode.gain) {
      this.gainNode.gain.value = this.getGain();
    }
  }

  getGain() {
    if (!this.active) {
      return 0;
    }

    return this.normalization ? this.volume * this.normalizationGain : this.volume;
  }

  // Loudest level (LUFS) this track can reach without its true peak going over the max,
  // null when the loudness analysis is missing or unusable
  getMaxReachableLoudness() {
    const loudness = this.getLoudness();
    if (loudness === null || !Number.isFinite(loudness.integrated)) {
      return null;
    }

    const { integrated, true_peak: truePeak } = loudness;

    // without true peak we can't know if a boost would clip, so the track can only be attenuated
    return Number.isFinite(truePeak)
      ? integrated + (NORMALIZATION_MAX_TRUE_PEAK - truePeak)
      : integrated;
  }

  // linear gain bringing the track to the common target, 1 (no change) when it can't be computed
  computeNormalizationGain() {
    const maxReachableLoudness = this.getMaxReachableLoudness();
    if (this.normalizationTarget === null || maxReachableLoudness === null) {
      return 1;
    }

    // the common target should never exceed what the track can reach, but we cap it anyway as a safety
    const gainDb = Math.min(this.normalizationTarget, maxReachableLoudness) - this.getLoudness().integrated;

    return 10 ** (gainDb / 20);
  }

  getLoudness() {
    if (!this.src) {
      return null;
    }

    let { loudness } = this.src;
    if (typeof loudness === 'string') {
      try {
        loudness = JSON.parse(loudness);
      } catch (e) {
        return null;
      }
    }

    return loudness !== null && typeof loudness === 'object' ? loudness : null;
  }

  // cue to draw, in seconds (null: not set)
  setCue(start, end) {
    this.cueStart = start;
    this.cueEnd = end;
    this.refreshTimeline();
  }

  getDuration() {
    if (!this.buffer) {
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
    this.applyGain();

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
    this.waveform.draw(
      this.lastPixel,
      this.active,
      this.timeToPixel(this.cueStart),
      this.timeToPixel(this.cueEnd)
    );
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

    // a click seeks, a click + drag creates a cue (or adjusts it when grabbing one of its edges)
    canvasElem.addEventListener('pointerdown', (e) => this.onPointerDown(e, canvasElem));
    canvasElem.addEventListener('pointermove', (e) => this.onPointerMove(e, canvasElem));
    canvasElem.addEventListener('pointerup', (e) => this.onPointerUp(e, canvasElem));
    canvasElem.addEventListener('pointercancel', () => this.onPointerCancel());

    canvasParentElem.appendChild(canvasElem);

    return canvasElem;
  }

  // ---------- POINTER (seek & cue drag) ----------

  onPointerDown(e, canvasElem) {
    if (e.button !== 0 || !this.tracksMaxDuration) {
      return;
    }

    // avoid selecting the page text while dragging
    e.preventDefault();
    // keep receiving the events when the pointer leaves the canvas during the drag
    canvasElem.setPointerCapture(e.pointerId);

    const time = this.eventToTime(e, canvasElem);

    this.drag = {
      originX: e.clientX,
      originTime: time,
      // fixed side of the cue being dragged: the opposite edge when grabbing an edge, otherwise where the drag started
      anchorTime: this.getDragAnchorTime(this.getCueEdgeAt(e, canvasElem), time),
      dragging: false
    };
  }

  onPointerMove(e, canvasElem) {
    if (this.drag === null) {
      // hovering: show that an edge of the cue can be grabbed
      canvasElem.style.cursor = this.getCueEdgeAt(e, canvasElem) !== null ? 'ew-resize' : '';
      return;
    }

    // small moves are still considered a click
    if (this.drag.dragging === false && Math.abs(e.clientX - this.drag.originX) < CUE_DRAG_THRESHOLD_PX) {
      return;
    }

    this.drag.dragging = true;
    this.ee.emit('cueDrag', this.toCueRange(this.drag.anchorTime, this.eventToTime(e, canvasElem)));
  }

  onPointerUp(e, canvasElem) {
    if (this.drag === null) {
      return;
    }

    const { originTime, anchorTime, dragging } = this.drag;
    this.drag = null;

    if (dragging === false) {
      this.ee.emit('waveformClick', { track_hash: this.src.hash, time: originTime });
      return;
    }

    const range = this.toCueRange(anchorTime, this.eventToTime(e, canvasElem));
    if (range.end - range.start < CUE_MIN_DURATION_SECONDS) {
      this.ee.emit('cueDragCancel');
      return;
    }

    this.ee.emit('cueDragEnd', range);
  }

  onPointerCancel() {
    if (this.drag === null) {
      return;
    }

    const { dragging } = this.drag;
    this.drag = null;

    if (dragging === true) {
      this.ee.emit('cueDragCancel');
    }
  }

  getDragAnchorTime(edge, time) {
    if (edge === 'start') {
      return this.cueEnd;
    }

    if (edge === 'end') {
      return this.cueStart;
    }

    return time;
  }

  // time (seconds) at the pointer position, the canvas spanning the duration of the longest track
  eventToTime(e, canvasElem) {
    const rect = canvasElem.getBoundingClientRect();
    if (rect.width === 0) {
      return 0;
    }

    const x = Math.min(Math.max(e.clientX - rect.left, 0), rect.width);

    return (x * this.tracksMaxDuration) / rect.width;
  }

  // edge of the cue ('start' / 'end') under the pointer, null if none. Only complete cues can be adjusted
  getCueEdgeAt(e, canvasElem) {
    if (this.cueStart === null || this.cueEnd === null || !this.tracksMaxDuration) {
      return null;
    }

    const rect = canvasElem.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const timeToX = (time) => (time * rect.width) / this.tracksMaxDuration;
    // edges after the end of this track are not drawn on it, so they can't be grabbed here
    const duration = this.getDuration();

    const distanceToStart = this.cueStart <= duration ? Math.abs(x - timeToX(this.cueStart)) : Infinity;
    const distanceToEnd = this.cueEnd <= duration ? Math.abs(x - timeToX(this.cueEnd)) : Infinity;

    if (Math.min(distanceToStart, distanceToEnd) > CUE_EDGE_GRAB_PX) {
      return null;
    }

    return distanceToStart <= distanceToEnd ? 'start' : 'end';
  }

  // dragging backwards is allowed
  toCueRange(timeA, timeB) {
    return { start: Math.min(timeA, timeB), end: Math.max(timeA, timeB) };
  }

  createWaveform(canvasElem) {
    // we give to the waveform drawer the length of the canvas relative to the other tracks
    const trackWidthPercent = this.tracksMaxDuration === this.getDuration()
      ? '100' : (this.getDuration() * 100) / this.tracksMaxDuration;

    /* eslint-disable max-len */
    this.waveform = new Timeline(canvasElem, this.drawWaveformUnder, this.buffer, trackWidthPercent);
  }

  // ---------- UTILS ----------

  timeToPixel(time) {
    if (time === null || this.waveform === null || !this.tracksMaxDuration) {
      return null;
    }

    return Math.round((time * this.waveform.canvas.width) / this.tracksMaxDuration);
  }

  // current playback position in seconds, consistent with getCurrentPixel() whatever the player state
  getCurrentTime() {
    if (this.playerState === playerState.PLAYER_STOPPED) {
      return 0;
    } else if (this.source !== null && this.lastPlayingStartedAt !== null) {
      return ((Date.now() - this.lastPlayingStartedAt) / 1000) + this.currentSeconds;
    } else if (this.pausedAt !== null && this.currentSeconds !== null) {
      // currentSeconds already includes the time played before the pause
      return this.currentSeconds;
    }

    return 0;
  }

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
