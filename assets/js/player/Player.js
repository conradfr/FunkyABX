/* eslint-env browser */

import { COOKIE_TEST_WAVEFORM } from '../config/config';
import cookies from '../utils/cookies';
import LoaderFactory from './loader/LoaderFactory';
import Track from './Track';
import * as playerState from '../config/state';

export default class {
  constructor(tracks, rotateSeconds, rotate, loop, drawWaveform, ee, audioFiles) {
    this.ee = ee;
    this.audioFiles = audioFiles;

    this.rotateInterval = null;
    this.timeInterval = null;

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
    this.drawWaveform = drawWaveform;

    const trackList = this.tracks;

    // ---------- PLAYER EVENTS ----------

    this.ee.on('playing', (_trackHash) => {
      this.playing += 1;
      // playing is starting
      if (this.playing === 1) {
        this.ee.emit('push_event', { event: 'playing', data: {} });
        this.startTime = this.ac.currentTime;
        this.currentTime = this.ac.currentTime;
      }
    });

    this.ee.on('stopping', (_trackHash, fromEnding) => {
      this.playing -= 1;
      if (this.playing === 0) {
        this.tracks.forEach((trackObj) => {
          trackObj.refreshTimeline();
        });

        if (this.rotateInterval !== null && (fromEnding !== true || this.loop === false)) {
          clearInterval(this.rotateInterval);
          this.rotateInterval = null;
        }

        if (this.timeInterval !== null) {
          clearInterval(this.timeInterval);
          this.timeInterval = null;
        }

        let restarted = false;
        if (this.state === playerState.PLAYER_PLAYING) {
          if (this.loop === true) {
            restarted = true;
            this.play();
          } else {
            this.setState(playerState.PLAYER_STOPPED);
          }
        }

        if (restarted === false) {
          this.ee.emit('push_event', { event: 'stopping', data: {} });
        }
      }
    });

    /* eslint-disable camelcase */
    this.ee.on('waveform-click', (params) => {
      const { track_hash, time } = params;
      this.play(track_hash, time);
    });

    // ---------- LOAD ----------

    this.loadPromises = trackList.map((trackInfo) => {
      const loader = LoaderFactory.createLoader(
        trackInfo,
        this.ac,
        this.ee,
        this.audioFiles
      );
      return loader.load();
    });

    Promise.all(this.loadPromises)
      .then((audioBuffers) => {
        this.ee.emit('push_event', { event: 'tracksLoaded', data: {} });

        this.tracks = audioBuffers.map((audioBuffer, index) => {
          /* eslint-disable max-len */
          return new Track(trackList[index], this.drawWaveform, audioBuffer, this.ac, this.ee, this.state);
        });

        // const durations = this.tracks.map((trackObj) => trackObj.getDuration());

        const maxDurationTrack = this.tracks.reduce(
          (acc, curr) => curr.getDuration() > acc.getDuration() ? curr : acc
        );

        // maxDuration = Math.max(durations);
        this.maxDuration = maxDurationTrack.getDuration();

        /* eslint-disable no-param-reassign */
        this.tracks = this.tracks.map((trackObj) => {
          trackObj.tracksMaxDuration = this.maxDuration;
          trackObj.drawTimeline();
          return trackObj;
        });
      })
      .catch((error) => {
        this.ee.emit('push_event', { event: 'tracksError', data: { error } });
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
    let nextTrackIndex = (from === undefined ? this.currentTrackIndex : from) + 1;
    if (nextTrackIndex >= this.tracks.length) {
      nextTrackIndex = 0;
    }

    return nextTrackIndex;
  }

  getPrevTrackIndex(from) {
    let prevTrackIndex = (from === undefined ? this.currentTrackIndex : from) - 1;
    if (prevTrackIndex < 0) {
      prevTrackIndex = this.tracks.length - 1;
    }

    return prevTrackIndex;
  }

  getTrackIndexFromHash(track_hash) {
    return this.tracks.findIndex(track => track.src.hash === track_hash);
  }

  toggleDrawWaveform() {
    this.drawWaveform = !this.drawWaveform;
    cookies.set(COOKIE_TEST_WAVEFORM, this.drawWaveform);
    this.tracks.forEach((trackObj) => {
      trackObj.setDrawWaveformUnder(this.drawWaveform);
    });
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
        this.ee.emit('push_event', {
          event: 'currentTrackHash',
          data: { track_hash: track.src.hash }
        });
      }

      playoutPromises.push(
        track.play(startTime)
      );
    });

    Promise.all(playoutPromises);

    if (this.rotateInterval === null) {
      this.setRotate();
    }

    if (this.timeInterval === null) {
      // keep current play time updated
      /* eslint-disable operator-linebreak */
      this.timeInterval =
        setInterval(() => {
          this.currentTime = this.ac.currentTime;
          this.tracks.forEach((track) => {
            track.refreshTimeline();
          });
        }, 25);
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

  togglePlay(goBack) {
    if (this.state === playerState.PLAYER_PLAYING) {
      goBack === true ? this.stop() : this.pause();
      return;
    }

    this.play(null, goBack === true ? 0 : null);
  }

  goToTrack(trackNumber, goBack) {
    if (trackNumber > this.tracks.length) {
      return;
    }

    const track = this.tracks[trackNumber - 1];

    if (this.startTime + track.getDuration() < this.currentTime) {
      return;
    }

    this.switchToTrack(trackNumber - 1, goBack);
    this.setRotate();
  }

  goToNext(goBack) {
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

    this.switchToTrack(nextTrackIndex, goBack);
    this.setRotate();
  }

  goToPrev(goBack) {
    let prevTrackIndex = null;
    let index = this.currentTrackIndex;
    do {
      prevTrackIndex = this.getPrevTrackIndex(index);
      const prevTrack = this.tracks[prevTrackIndex];

      if (this.startTime + prevTrack.getDuration() < this.currentTime) {
        index = prevTrackIndex;
        prevTrackIndex = null;
      }
    } while (prevTrackIndex === null && index !== this.currentTrackIndex);

    if (prevTrackIndex === this.currentTrackIndex) {
      return;
    }

    this.switchToTrack(prevTrackIndex, goBack);
    this.setRotate();
  }

  // ---------- INTERNAL----------

  switchToTrack(nextTrackIndex, goBack) {
    this.currentTrackIndex = nextTrackIndex;

    this.tracks.forEach((track, index) => {
      track.setActive(index === nextTrackIndex);
      if (index === nextTrackIndex) {
        this.ee.emit('push_event', {
          event: 'currentTrackHash',
          data: { track_hash: track.src.hash }
        });
      }
    });

    if (goBack === true) {
      this.back();
    }
  }

  setRotate() {
    if (this.rotateInterval !== null) {
      clearInterval(this.rotateInterval);
      this.rotateInterval = null;
    }

    if (this.rotate === false || this.isPlaying() === false) {
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
