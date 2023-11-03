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
        cookies.set(`${COOKIE_TEST_TAKEN}_${testId}_tracks_order`, JSON.stringify(tracks_order), {'max-age': null});
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
  }
};

export default TestHook;
