import cookies from '../utils/cookies';
import { COOKIE_TEST_TAKEN } from '../config/config';

let audioFiles = null;

/* eslint-disable no-undef */
const TestResultsHook = {
  setAudioFiles(files) {
    audioFiles = files;
  },
  mounted() {
    const testId = this.el.dataset.testid;
    this.audio = null;
    this.ctrlPressed = false;

    // ensure the visitor has not already taken the test, otherwise report to the LV
    if (cookies.has(`${COOKIE_TEST_TAKEN}_${testId}`) === false
      && cookies.get(`${COOKIE_TEST_TAKEN}_${testId}`) !== 'true'
      && localStorage[`${testId}_taken`] === undefined
      && localStorage.getItem(`${testId}_taken`) !== 'true') {
      this.pushEvent('test_not_taken', {});
    }

    // Send visitor test data to the result page
    if (localStorage[testId] !== undefined) {
      const results = JSON.parse(localStorage.getItem(testId));
      this.pushEvent('results', results);
    }

    // Send track order from test session if any
    if (sessionStorage.getItem(`${COOKIE_TEST_TAKEN}_${testId}_tracks_order`) !== undefined) {
      this.pushEvent('tracks_order', JSON.parse(sessionStorage.getItem(`${COOKIE_TEST_TAKEN}_${testId}_tracks_order`)));
    }

    // note: not sure why ls has "_id" and not the cookie. Keeping it for retro-compatibility.
    if (localStorage[`${testId}_taken_session_id`] !== undefined) {
      this.pushEvent('session_id', localStorage[`${testId}_taken_session_id`]);
    } else if (cookies.has(`${COOKIE_TEST_TAKEN}_${testId}_session`) === true) {
      this.pushEvent('session_id', cookies.get(`${COOKIE_TEST_TAKEN}_${testId}_session`));
    }

    /* eslint-disable camelcase */
    this.play = async (event) => {
      const { test_local, track_id, track_url } = event.detail;
      let audio = null;

      if (test_local === true && audioFiles[track_id]) {
        const file = audioFiles[track_id];
        const fileUrl = URL.createObjectURL(file);

        audio = new Audio(fileUrl);
      } else {
        audio = new Audio(track_url);
      }

      if (this.audio !== null) {
        audio.volume = 0;
      }

      audio.loop = true;
      audio.play();

      // if track already playing we try to match the current time and limit the cut between the two plays

      if (this.audio !== null) {
        if (this.ctrlPressed !== true) {
          audio.currentTime = this.audio.currentTime;
        }

        this.audio.volume = 0;
      }

      if (this.audio !== null) {
        audio.volume = 1;
        this.audio.pause();
        this.audio = null;
      }

      this.audio = audio;

      this.pushEvent('playing_audio', { track_id });
    };

    this.stop = () => {
      if (this.audio !== null) {
        this.audio.pause();
        this.audio = null;
        this.pushEvent('stopping_audio');
      }
    };

    window.addEventListener('play_result', this.play, false);
    window.addEventListener('stop_result', this.stop, false);
  },
  destroyed() {
    this.stop();

    window.removeEventListener('play_result', this.play, false);
    window.removeEventListener('stop_result', this.stop, false);
  }
};

export default TestResultsHook;
