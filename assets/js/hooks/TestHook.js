import cookies from '../utils/cookies';
import { COOKIE_TEST_TAKEN } from '../config/config';

const TestHook = {
  mounted() {
    const testId = this.el.dataset.testid;

    // ensure the visitor has not already taken the test, otherwise report to the LV
    if ((cookies.has(`${COOKIE_TEST_TAKEN}_${testId}`) &&
        cookies.get(`${COOKIE_TEST_TAKEN}_${testId}`) === 'true')
      || (localStorage[`${testId}_taken`] !== undefined
        && localStorage.getItem(`${testId}_taken`) === 'true')) {
      this.pushEvent('test_already_taken', {});
    }

    this.handleEvent('store_test', (params) => {
      const {choices, session_id} = params;
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}`, true);
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}_session`, session_id);
      localStorage.setItem(testId, JSON.stringify(choices));
      localStorage.setItem(`${testId}_taken`, true);
      localStorage.setItem(`${testId}_taken_session_id`, session_id);
    });

    this.handleEvent('bypass_test', () => {
      cookies.set(`${COOKIE_TEST_TAKEN}_${testId}`, true);
      localStorage.setItem(`${testId}_taken`, true);
    });

    this.warningReload = (e) => {
      e.preventDefault();
      // the text is useless
      return 'Are you sure you want to leave/reload? Tracks will be lost.';
    }

    this.handleEvent('setWarningLocalTestReload', (params) => {
      if (params.set === false && this.preventReloadSet === true) {
        this.preventReloadSet = false;
        window.removeEventListener('beforeunload', this.warningReload);
        return;
      }

      if (params.set === true && this.preventReloadSet !== true) {
        this.preventReloadSet = true;
        window.addEventListener('beforeunload', this.warningReload);
      }
    });
  },
  destroyed() {
    if (this.preventReloadSet === true) {
      window.removeEventListener('beforeunload', this.warningReload);
    }
  }
}

export default TestHook;
