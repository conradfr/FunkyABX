/* eslint-disable no-undef */
const DownloadTestFilesHook = {
  mounted() {
    this.handleEvent('download_file', (params) => {
      this.processDownload(params);
    });
  },

  /*
    1/ The iframe is used to allow to launch multiple download in parallel.
    check: https://stackoverflow.com/questions/2339440/download-multiple-files-with-a-single-action/9425731#9425731
    2/ The blob is because Firefox ignores the download attribute on cross-origin URLs so we download the file first
   */
  async processDownload(params) {
    const { title, url } = params;
    const ext = new URL(url).pathname.split('.').pop();

    try {
      const response = await fetch(url);
      const blob = await response.blob();
      const blobUrl = URL.createObjectURL(blob);

      let iframe = document.createElement('iframe');
      iframe.style.visibility = 'collapse';
      document.body.append(iframe);

      iframe.contentDocument.write(
        `<a href="${blobUrl}" download="${title}.${ext}">`
      );
      iframe.contentDocument.getElementsByTagName('a')[0].click();

      setTimeout(() => {
        iframe.remove();
        URL.revokeObjectURL(blobUrl);
      }, 2000);
    } catch (e) {
      console.error('Download failed:', e);
    }
  },
};

export default DownloadTestFilesHook;
