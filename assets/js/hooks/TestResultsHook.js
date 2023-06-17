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

    // Send visitor test data to the result page
    if (localStorage[testId] !== undefined) {
      const results = JSON.parse(localStorage.getItem(testId));
      this.pushEvent('results', results);
    }

    if (localStorage[`${testId}_taken_session`] !== undefined) {
      this.pushEvent('session_id', localStorage[`${testId}_taken_session`]);
    } else if (cookies.has(`${COOKIE_TEST_TAKEN}_${testId}_session`) === true) {
      this.pushEvent('session_id', cookies.get(`${COOKIE_TEST_TAKEN}_${testId}_session`));
    }

    // ensure the visitor has not already taken the test, otherwise report to the LV
    if (cookies.has(`${COOKIE_TEST_TAKEN}_${testId}`) === false
      && cookies.get(`${COOKIE_TEST_TAKEN}_${testId}`) !== 'true'
      && localStorage[`${testId}_taken`] === undefined
      && localStorage.getItem(`${testId}_taken`) !== 'true') {
      this.pushEvent('test_not_taken', {});
    }

    /* eslint-disable camelcase */
    this.play = async (e) => {
      const { test_local, track_id, track_url } = e.detail;
      let audio = null;

      if (test_local === true) {
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
        audio.currentTime = this.audio.currentTime;
        this.audio.volume = 0;
      }

      if (this.audio !== null) {
        audio.volume = 1;
        this.audio.pause();
        this.audio = null;
      }

      this.audio = audio;

      this.pushEvent('playing', { track_id });
    };

    this.stop = () => {
      if (this.audio !== null) {
        this.audio.pause();
        this.audio = null;
        this.pushEvent('stopping');
      }
    };

    window.addEventListener('play', this.play, false);
    window.addEventListener('stop', this.stop, false);
  },
  destroyed() {
    this.stop();
    window.removeEventListener('play', this.play, false);
    window.removeEventListener('stop', this.stop, false);
  }
};

export default TestResultsHook;
