import { directoryOpen, fileOpen } from 'browser-fs-access';
import cookies from '../utils/cookies';

let audioFiles = null;

/* eslint-disable no-undef */
/* eslint-disable no-restricted-globals */
const LocalTestFormHook = {
  setAudioFiles(files) {
    audioFiles = files;
  },
  mounted() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map((tooltipTriggerEl) => new bootstrap.Tooltip(tooltipTriggerEl));

    const isAllowedExt = (filename) => {
      const arr = filename.split('.');
      return ['wav', 'mp3', 'aac', 'flac'].indexOf(arr.pop()) !== -1;
    };

    this.handleEvent('store_params_and_redirect', ({ url, params }) => {
      params.forEach((param) => {
        if (param.value !== null) {
          cookies.set(param.name, param.value);
        }
      });

      this.pushEvent('redirect', { url });
    });

    // ---------- DRAG & DROP ----------

    this.ondrop = async (event) => {
      event.preventDefault();

      for await (const item of event.dataTransfer.items) {
        if (item.kind === 'file') {
          const file = item.getAsFile();

          if (isAllowedExt(file.name)) {
            const id = self.crypto.randomUUID();
            audioFiles[id] = file;

            this.pushEvent('track_added', { id: id, filename: file.name });
          }
        }
      }
    };

    this.dropElem = document.getElementById('local_files_drop_zone');

    if (this.dropElem) {
      this.dropElem.addEventListener('drop', this.ondrop, false);
    }

    // ---------- FILE PICKER ----------

    this.fileButton = document.getElementById('local-file-picker');

    this.fileClick = async () => {
      const files = await fileOpen({
        mimeTypes: ['audio/*'],
        extensions: ['.wav', '.mp3', '.aac', '.flac'],
        multiple: true,
      });

      files.forEach(async file => {
        if (isAllowedExt(file.name)) {
          const id = self.crypto.randomUUID();
          audioFiles[id] = file;

          this.pushEvent('track_added', { id: id, filename: file.name });
        }
      });
    };

    this.fileButton.addEventListener('click', this.fileClick, false);

    // ---------- FOLDER PICKER ----------

    this.folderButton = document.getElementById('local-folder-picker');

    this.folderClick = async () => {
      const folder = await directoryOpen();

      folder.forEach(async file => {
        if (isAllowedExt(file.name)) {
          const id = self.crypto.randomUUID();
          audioFiles[id] = file;

          this.pushEvent('track_added', { id: id, filename: file.name });
        }
      });
    };

    this.folderButton.addEventListener('click', this.folderClick, false);
  },
  destroyed() {
    this.fileButton.removeEventListener('click', this.fileClick, false);
    this.folderButton.removeEventListener('click', this.folderClick, false);
    if (this.dropElem) {
      this.dropElem.removeEventListener('drop', this.ondrop, false);
    }
  }
};

export default LocalTestFormHook;
