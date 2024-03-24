import cookies from '../utils/cookies';
import localStorageUtils from '../utils/localStorageUtils';
import { COOKIE_TEST_TAKEN } from '../config/config';

/* eslint-disable no-undef */
const TestHook = {
  mounted() {
    const testId = this.el.dataset.testid;

    // ensure the visitor has not already taken the test, otherwise report to the LV
    if ((cookies.has(`${COOKIE_TEST_TAKEN}_${testId}`)
        && cookies.get(`${COOKIE_TEST_TAKEN}_${testId}`) === 'true')
      || (localStorage[`${testId}_taken`] !== undefined
        && localStorage.getItem(`${testId}_taken`) === 'true')) {
      this.pushEvent('test_already_taken', {});
    }

    this.handleEvent('store_test', (params) => {
      const { choices, session_id, tracks_order } = params;
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}`, true);
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}_session`, session_id);

      if (tracks_order) {
        sessionStorage.setItem(`${COOKIE_TEST_TAKEN}_${testId}_tracks_order`, JSON.stringify(tracks_order));
      }

      // todo better localStorage implementation
      try {
        localStorage.setItem(testId, JSON.stringify(choices));
        localStorage.setItem(`${testId}_taken`, true);
        // note: not sure why ls has "_id" and not the cookie. Keeping it for retro-compatibility.
        localStorage.setItem(`${testId}_taken_session_id`, session_id);
      } catch(e) {
        localStorageUtils.clearIfFull(e);
      }
    });

    this.handleEvent('bypass_test', () => {
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}`, true);
      localStorage.setItem(`${testId}_taken`, true);
    });

    this.deleteTest = () => {
      cookies.remove(`${COOKIE_TEST_TAKEN}_${testId}`);
      cookies.remove(`${COOKIE_TEST_TAKEN}_${testId}_session`);

      sessionStorage.removeItem(`${COOKIE_TEST_TAKEN}_${testId}_tracks_order`);

      localStorage.removeItem(testId);
      localStorage.removeItem(`${testId}_taken`);
      localStorage.removeItem(`${testId}_taken_session_id`);

      window.location.reload();
    };

    window.addEventListener('delete_test', this.deleteTest, false);
  },
  destroyed() {
    window.removeEventListener('delete_test', this.deleteTest, false);
  }
};

export default TestHook;
