import cookies from '../utils/cookies'
import clipboard from '../utils/clipboard'
import { COOKIE_TEST_AUTHOR } from '../config/config'

/* eslint-disable no-undef */
const TestFormHook = {
  mounted() {
    this.tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    this.tooltipTriggerList.map((tooltipTriggerEl) => new bootstrap.Tooltip(tooltipTriggerEl));

    this.handleEvent('revalidate', () => {
      setTimeout(() => {
        const elem = document.getElementById('test-form_type_regular');
        if (elem) {
          elem.dispatchEvent(
            new Event('input', {bubbles: true})
          )
        }
      }, 2000);
    })

    this.handleEvent('clipboard', (params) => {
      clipboard.copy(params.text);
    })

    this.handleEvent('saveTest', (params) => {
      if (params.test_author !== undefined && params.test_author !== null && params.test_author !== '') {
        cookies.set(COOKIE_TEST_AUTHOR, params.test_author)
      }

      // test if from a logged user
      if (params.test_access_key === undefined || params.test_access_key === null) {
        return
      }

      cookies.set(`test_${params.test_id}`, params.test_access_key)
    })

    this.handleEvent('deleteTest', (params) => {
      // test if from a logged user
      if (params.test_access_key === undefined || params.test_access_key === null) {
        return
      }

      cookies.remove(`test_${params.test_id}`)
    });

    this.handleEvent('store_params', ({ params }) => {
      params.forEach((param) => {
        if (param.value !== null) {
          cookies.set(param.name, param.value)
        }
      })
    })
  },
  updated() {
    this.tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    this.tooltipTriggerList.map((tooltipTriggerEl) => new bootstrap.Tooltip(tooltipTriggerEl));
  },
};

export default TestFormHook;
