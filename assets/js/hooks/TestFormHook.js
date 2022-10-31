import cookies from '../utils/cookies';
import clipboard from '../utils/clipboard';
import { COOKIE_TEST_AUTHOR } from '../config/config';

const TestFormHook = {
  mounted() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl)
    })

    this.handleEvent('clipboard', (params) => {
      clipboard.copy(params.text);
    });

    this.handleEvent('saveTest', (params) => {
      if (params.test_author !== undefined && params.test_author !== null && params.test_author !== '') {
        cookies.set(COOKIE_TEST_AUTHOR, params.test_author);
      }

      // test if from a logged user
      if (params.test_access_key === undefined || params.test_access_key === null) {
        return;
      }

      cookies.set(`test_${params.test_id}`, params.test_access_key);
    });

    this.handleEvent('deleteTest', (params) => {
      // test if from a logged user
      if (params.test_access_key === undefined || params.test_access_key === null) {
        return;
      }

      cookies.remove(`test_${params.test_id}`);
    });

    this.handleEvent('store_params', ({params}) => {
      params.forEach((param) => {
        if (param.value !== null) {
          cookies.set(param.name, param.value);
        }
      })
    });
  }
}

export default TestFormHook;
