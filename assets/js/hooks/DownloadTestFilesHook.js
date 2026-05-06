import cookies from '../utils/cookies';
import localStorageUtils from '../utils/localStorageUtils';
import { COOKIE_TEST_TAKEN } from '../config/config';

/* eslint-disable no-undef */
const DownloadTestFilesHook = {
  mounted() {
    this.handleEvent('download_file', (params) => {
      const { title, url } = params;
      const ext = new URL(url).pathname.split('.').pop();

      console.log(title);
      console.log(url);
      console.log(ext);

      const a = document.createElement('a');
      a.href = url;
      a.download = `${title}.${ext}`;
      document.body.appendChild(a);
      a.click();
      a.remove();
    });
  },
};

export default DownloadTestFilesHook;
