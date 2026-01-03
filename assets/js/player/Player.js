/* eslint-env browser */

import {
  COOKIE_TEST_WAVEFORM,
  COOKIE_DEVICE
} from '../config/config';
import cookies from '../utils/cookies';
import time from '../utils/time';
import LoaderFactory from './loader/LoaderFactory';
import Track from './Track';
import * as playerState from '../config/state';

export default class {
  constructor(tracks, rotateSeconds, rotate, loop, volume, drawWaveform, ee, audioFiles) {
    this.ee = ee;
    this.audioFiles = audioFiles;

    this.rotateInterval = null;
    this.timeInterval = null;

    // state is the UI state
    this.state = playerState.PLAYER_STOPPED;
    // this is more the actual state of the tracks
    this.playing = 0;
    this.volume = volume;

    this.currentTrackIndex = 0;
    this.currentTime = 0.0;
    this.startTime = 0.0;
    this.maxDuration = 0;
    this.maxDurationTrack = null;

    const AudioContext = window.AudioContext || window.webkitAudioContext;
    this.ac = new AudioContext();

    this.tracks = tracks;
    this.rotateSeconds = rotateSeconds;
    this.rotate = rotate;
    this.loop = loop;
    this.drawWaveform = drawWaveform;

    this.startCueTime = null;

    const trackList = this.tracks;

    // ---------- PLAYER EVENTS ----------

    this.ee.on('playing', (_trackHash) => {
      this.playing += 1;
      // playing is starting
      if (this.playing === 1) {
        this.ee.emit('push_event', { event: 'playing', data: {} });
        this.startTime = time.getTimeInMs();
        this.currentTime = time.getTimeInMs();
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

    this.ee.on('audiorequeststatechange', ({ track_hash, state }) => {
      this.ee.emit('push_event', {
        event: 'track_state',
        data: {
          track_hash: track_hash,
          state: state
        }
      });
    });

    this.ee.on('loadprogress', ({ track_hash, progress }) => {
      this.ee.emit('push_event', {
        event: 'track_progress',
        data: {
          track_hash: track_hash,
          progress: progress
        }
      });
    });

    /* eslint-disable camelcase */
    this.ee.on('waveformClick', (params) => {
      const { track_hash, time } = params;
      this.play(track_hash, time, true);
    });

    this.ee.on('setCueStartTime', async (params) => {
      this.startCueTime = params;
    });

    this.ee.on('cueIsOver', async (params) => {
      this.play(null, params || 0);
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
        this.ee.emit('push_event', { event: 'tracks_loaded', data: {} });

        this.tracks = audioBuffers.map((audioBuffer, index) => {
          /* eslint-disable max-len */
          return new Track(trackList[index], this.drawWaveform, audioBuffer, this.volume, this.ac, this.ee, this.state);
        });

        this.maxDurationTrack = this.tracks.reduce(
          (acc, curr) => curr.getDuration() > acc.getDuration() ? curr : acc
        );

        /*
          The player can't know when a cue end is reached
          So we delegate that to the longest Track
         */
        this.maxDurationTrack.cueMaster = true;
        this.maxDuration = this.maxDurationTrack.getDuration();


        /* eslint-disable no-param-reassign */
        this.tracks = this.tracks.map((trackObj) => {
          trackObj.tracksMaxDuration = this.maxDuration;
          trackObj.drawTimeline();
          return trackObj;
        });
      })
      .catch((error) => {
        this.ee.emit('push_event', { event: 'tracks_error', data: { error } });
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
      nextTrackIndex = this.tracks[0].src.reference_track === true ? 1 : 0;
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

  play(track_hash, startTime, resetRotate) {
    this.setState(playerState.PLAYER_PLAYING);
    if (resetRotate) {
      this.setRotate();
    }

    if (track_hash !== undefined && track_hash !== null) {
      const askedTrackIndex = this.getTrackIndexFromHash(track_hash);
      if (askedTrackIndex !== undefined) {
        // currently playing
        if (this.isPlaying() === true && (startTime === undefined || startTime === null)) {
          this.switchToTrack(askedTrackIndex, startTime);
          // this.setRotate();
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
          event: 'current_track_hash',
          data: { track_hash: track.src.hash }
        });
      }

      playoutPromises.push(
        track.play(startTime ?? this.startCueTime)
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
          this.currentTime = time.getTimeInMs();
          this.tracks.forEach((track) => {
            track.refreshTimeline();
          });
        }, 25);
    }
  }

  stop() {
    this.setState(playerState.PLAYER_STOPPED);

    this.tracks.forEach((track) => {
      if (typeof track.stop === 'function') {
        track.stop();
      }
    });
  }

  pause() {
    this.setState(playerState.PLAYER_PAUSED);

    this.tracks.forEach((track) => {
      if (typeof track.pause === 'function') {
        track.pause();
      }
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
      if (goBack) {
        this.stop();
      } else {
        this.pause();
      }
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
      if (nextTrackIndex === index) {
        return;
      }
      const nextTrack = this.tracks[nextTrackIndex];

      // next track is too short
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

      // prev track is too short
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

  // ---------- VOLUME ----------

  async setVolume(volume) {
    this.volume = volume;
    // we sync to tracks as they don't have access to the player
    this.tracks.map(item => {
      if (item instanceof Track) {
        item.setVolume(volume)
      }
    });
  }

  // ---------- CUE ----------

  async setStartCue() {
    // we sync to tracks as they don't have access to the player
    return await Promise.all(this.tracks.map(item => item.setStartCueTime()));
  }

  async setEndCue() {
    // we sync to tracks as they don't have access to the player
    return await Promise.all(this.tracks.map(item => item.setEndCueTime(this.tracks.length)));
  }

  // ---------- OUTPUT DEVICE ----------

  setOutputDevice(deviceId) {
    this.ac.setSinkId(deviceId);
    /*
    cookies.set(COOKIE_DEVICE_SAVE, true);
    cookies.set(COOKIE_DEVICE, deviceId);
    */
    sessionStorage.setItem(COOKIE_DEVICE, deviceId);
  }

  // ---------- INTERNAL ----------

  switchToTrack(nextTrackIndex, goBack) {
    this.currentTrackIndex = nextTrackIndex;

    this.tracks.forEach((track, index) => {
      track.setActive(index === nextTrackIndex);
      if (index === nextTrackIndex) {
        this.ee.emit('push_event', {
          event: 'current_track_hash',
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
          console.log('------');
          nextTrackIndex = this.getNextTrackIndex(index);
          console.log(nextTrackIndex);
          const nextTrack = this.tracks[nextTrackIndex];

          console.log(this.startTime);
          console.log(nextTrack.getDuration());
          console.log(this.currentTime);

          // next track is too short
          if (this.startTime + nextTrack.getDuration() < this.currentTime) {
            console.log('TOO SHORT ??');
            index = nextTrackIndex;
            nextTrackIndex = null;
          }
        } while (nextTrackIndex === null && index !== this.currentTrackIndex);

        // did not find a track to skip to (all others tracks too short?)
        if (nextTrackIndex === this.currentTrackIndex) {
          return;
        }

        this.switchToTrack(nextTrackIndex);
      }, this.rotateSeconds);
  }
}
