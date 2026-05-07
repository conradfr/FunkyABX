import { directoryOpen, fileOpen } from 'browser-fs-access';
import JSZip from 'jszip';
import cookies from '../utils/cookies';

let audioFiles = null;

/* eslint-disable no-undef */
/* eslint-disable no-restricted-globals */
const LocalTestFormHook = {
  setAudioFiles(files) {
    audioFiles = files;
  },
  mounted() {
    this.tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    this.tooltipTriggerList.map((tooltipTriggerEl) => new bootstrap.Tooltip(tooltipTriggerEl));

    const isAllowedExt = (filename) => {
      const arr = filename.split('.');
      return ['wav', 'mp3', 'aac', 'flac'].indexOf(arr.pop()) !== -1;
    };

    const getFilesFromZip = async (file) => {
      const zip = await JSZip.loadAsync(file)
      const files = [];

      for (const [_path, entry] of Object.entries(zip.files)) {
        if (entry.dir || !isAllowedExt(entry.name) || entry.name.startsWith('__MACOSX/')) {
          continue;
        }

        const blob = await entry.async('blob');
        const audioFile = new File([blob], entry.name);
        files.push(audioFile);
      }

      return Promise.resolve(files);
    }

    const addAudioFile = (file) => {
      if (isAllowedExt(file.name)) {
        const id = self.crypto.randomUUID();
        audioFiles[id] = file;
        this.pushEvent('track_added', { id: id, filename: file.name });
        return 1;
      }

      return 0;
    };

    this.handleEvent('store_params_and_redirect', ({ url, params }) => {
      params.forEach((param) => {
        if (param.value !== null) {
          cookies.set(param.name, param.value);
        }
      });

      this.pushEvent('redirect', { url });
    });

    this.handleEvent('revalidate', () => {
      // timeout helps when multiple files selected
      setTimeout(() => {
        const elem = document.getElementById('test-form_type_regular');
        if (elem) {
          elem.dispatchEvent(
              new Event('input', {bubbles: true})
          )
        }
      }, 500);
    });

    // ---------- DRAG & DROP ----------

    this.ondrop = async (event) => {
      event.preventDefault();
      let counter = 0;

      for await (const item of event.dataTransfer.items) {
        if (item.kind === 'file') {
          const file = item.getAsFile();

          if (file.name.endsWith('.zip')) {
            const filesFromZip = await getFilesFromZip(file);
            for (const fileFromZip of filesFromZip) {
              counter += addAudioFile(fileFromZip);
            }
          }
          else  {
            counter += addAudioFile(file);
          }
        }
      }

      setTimeout(() => {
        document.getElementById('test-form_type_regular').dispatchEvent(
            new Event('input', {bubbles: true})
        )
      }, counter * 500);
    };

    this.dropElem = document.getElementById('local_files_drop_zone');

    if (this.dropElem) {
      this.dropElem.addEventListener('drop', this.ondrop, false);
    }

    // ---------- FILE PICKER ----------

    this.fileButton = document.getElementById('local-file-picker');

    this.fileClick = async () => {
      let counter = 0;
      const files = await fileOpen({
        mimeTypes: ['audio/*'],
        extensions: ['.wav', '.mp3', '.aac', '.flac', '.zip'],
        multiple: true,
      });

      for (const file of files) {
        if (file.name.endsWith('.zip')) {
          const filesFromZip = await getFilesFromZip(file);
          for (const fileFromZip of filesFromZip) {
            counter += addAudioFile(fileFromZip);
          }
        }
        else  {
          counter += addAudioFile(file);
        }
      }

      setTimeout(() => {
        document.getElementById('test-form_type_regular').dispatchEvent(
            new Event('input', {bubbles: true})
        )
      }, counter * 500);
    };

    this.fileButton.addEventListener('click', this.fileClick, false);

    // ---------- FOLDER PICKER ----------

    this.folderButton = document.getElementById('local-folder-picker');

    this.folderClick = async () => {
      const folder = await directoryOpen();

      let counter = 0;
      for (const file of folder) {
        if (isAllowedExt(file.name)) {
          const id = self.crypto.randomUUID();
          audioFiles[id] = file;
          counter++;
          this.pushEvent('track_added', { id: id, filename: file.name });
        }
      }

      setTimeout(() => {
        document.getElementById('test-form_type_regular').dispatchEvent(
            new Event('input', {bubbles: true})
        )
      }, counter * 35);
    };

    this.folderButton.addEventListener('click', this.folderClick, false);
  },
  updated() {
    this.tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    this.tooltipTriggerList.map((tooltipTriggerEl) => new bootstrap.Tooltip(tooltipTriggerEl));
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
