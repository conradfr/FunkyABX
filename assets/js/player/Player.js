/* eslint-env browser */

import LoaderFactory from './loader/LoaderFactory';
import Track from './Track';
import * as playerState from '../config/state';

export default class {
  constructor(tracks, rotateSeconds, rotate, loop, ee) {
    this.ee = ee;

    this.rotateInterval = null;
    this.timeInterval = null;
    this.loopTimeout = null;

    // state is the UI state
    this.state = playerState.PLAYER_STOPPED;
    // this is more the actual state of the tracks
    this.playing = 0;

    this.currentTrackIndex = 0;
    this.currentTime = 0;
    this.startTime = 0;
    this.maxDuration = 0;

    const AudioContext = window.AudioContext || window.webkitAudioContext;
    this.ac = new AudioContext();

    this.tracks = tracks;
    this.rotateSeconds = rotateSeconds;
    this.rotate = rotate;
    this.loop = loop;

    const trackList = this.tracks;

    // ---------- PLAYER EVENTS ----------

    this.ee.on('playing', (trackHash) => {
      this.playing += 1;
      // playing is starting
      if (this.playing === 1) {
        this.ee.emit('push_event', { event:'playing', data: {} });
        this.startTime = this.ac.currentTime;
        this.currentTime = this.ac.currentTime;
      }
    });

    this.ee.on('stopping', (trackHash) => {
      this.playing -= 1;
      if (this.playing === 0) {
        if (this.rotateInterval !== null) {
          clearInterval(this.rotateInterval);
          this.rotateInterval = null;
        }

        if (this.timeInterval !== null) {
          clearInterval(this.timeInterval);
          this.timeInterval = null;

          this.tracks.forEach((trackObj) => {
            trackObj.refreshWaveform();
          });
        }

        if (this.state === playerState.PLAYER_PLAYING) {
          this.setState(playerState.PLAYER_STOPPED);
        }

        this.ee.emit('push_event', { event: 'stopping', data: {} });
      }
    });

    this.ee.on('waveform-click', (params) => {
      const { track_hash, time } = params;
      this.ee.emit('push_event', { event: 'waveform-click', data: { track_hash, time } });
    });

    // ---------- LOAD ----------

    this.loadPromises = trackList.map((trackInfo) => {
      const loader = LoaderFactory.createLoader(
        trackInfo.url,
        this.ac,
        this.ee
      );
      return loader.load();
    });

    Promise.all(this.loadPromises)
      .then((audioBuffers) => {
        this.ee.emit('push_event', { event: 'tracksLoaded', data: {} });

        this.tracks = audioBuffers.map((audioBuffer, index) => {
          return new Track(trackList[index], audioBuffer, this.ac, this.ee, this.state);
        });

        // const durations = this.tracks.map((trackObj) => trackObj.getDuration());

        let maxDurationTrack = this.tracks.reduce(
          (acc, curr) => curr.getDuration() > acc.getDuration() ? curr : acc
        );

        // maxDuration = Math.max(durations);
        this.maxDuration = maxDurationTrack.getDuration();

        this.tracks = this.tracks.map((trackObj) => {
          trackObj.tracksMaxDuration = this.maxDuration;
          trackObj.drawWaveform();
          return trackObj;
        });
      });
  }

  // ---------- UTILS ----------

  setState(state) {
    this.state = state;
    this.ee.emit('player_state', state);
  }

  isPlaying() {
    return this.playing > 0;
  }

  getNextTrackIndex(from) {
    let nextTrack = (from === undefined ? this.currentTrackIndex : from) + 1;
    if (nextTrack >= this.tracks.length) {
      nextTrack = 0;
    }

    return nextTrack;
  }

  getTrackIndexFromHash(track_hash) {
    return this.tracks.findIndex(track => track.src.hash === track_hash);
  }

  // ---------- COMMANDS ----------

  play(track_hash, startTime) {
    this.setState(playerState.PLAYER_PLAYING);

    if (track_hash !== undefined && track_hash !== null) {
      const askedTrackIndex = this.getTrackIndexFromHash(track_hash);
      if (askedTrackIndex !== undefined) {
        if (this.isPlaying() === true && (startTime === undefined || startTime === null)) {
          this.switchToTrack(askedTrackIndex, startTime);
          this.setRotate();
          return;
        }
        /* if (this.isPlaying() === true && (startTime !== undefined || startTime !== null)) {
          // this.stop();
        } */
        this.currentTrackIndex = askedTrackIndex;
      }
    }

    const playoutPromises = [];

    this.tracks.forEach((track, index) => {
      track.setActive(index === this.currentTrackIndex);

      if (index === this.currentTrackIndex) {
        this.ee.emit('push_event', { event: 'currentTrackHash',
          data: { track_hash: track.src.hash } });
      }

      playoutPromises.push(
        track.play(startTime)
      );
    });

    Promise.all(playoutPromises);

    this.setRotate();

    if (this.timeInterval === null) {
      // keep current play time updated
      this.timeInterval =
        setInterval(() => {
          this.currentTime = this.ac.currentTime;
          this.tracks.forEach((track) => {
            track.refreshWaveform();
          });
        }, 250);
    }
  }

  stop() {
    this.setState(playerState.PLAYER_STOPPED);

    this.tracks.forEach((track) => {
      track.stop();
    });
  }

  pause() {
    this.setState(playerState.PLAYER_PAUSED);

    this.tracks.forEach((track) => {
      track.pause();
    });
  }

  back() {
    const wasPlaying = this.isPlaying();
    this.stop();
    if (wasPlaying === true) {
      // a small delay seems necessary
      setTimeout(() => this.play(), 250);
    }
  }

  // ---------- INTERNAL----------

  switchToTrack(nextTrackIndex, startTime) {
    this.currentTrackIndex = nextTrackIndex;

    this.tracks.forEach((track, index) => {
      track.setActive(index === nextTrackIndex);
      if (index === nextTrackIndex) {
        this.ee.emit('push_event', { event: 'currentTrackHash',
          data: { track_hash: track.src.hash } });
      }
    });
  }

  setRotate() {
    if (this.rotateInterval !== null) {
      clearInterval(this.rotateInterval);
      this.rotateInterval = null;
    }

    if (this.rotate === false) {
      return;
    }

    this.rotateInterval =
      setInterval(() => {
        let nextTrackIndex = null;
        let index = this.currentTrackIndex;
        do {
          nextTrackIndex = this.getNextTrackIndex(index);
          const nextTrack = this.tracks[nextTrackIndex];

          if (this.startTime + nextTrack.getDuration() < this.currentTime) {
            index = nextTrackIndex;
            nextTrackIndex = null;
          }
        } while (nextTrackIndex === null && index !== this.currentTrackIndex);

        if (nextTrackIndex === this.currentTrackIndex) {
          return;
        }

        this.switchToTrack(nextTrackIndex);
      }, this.rotateSeconds);
  }
}
