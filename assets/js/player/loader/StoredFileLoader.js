import Loader from './Loader';

export default class extends Loader {
  /**
   * Loads an audio file via indexDB.
   */
  async load() {
    const file = this.audioFiles[this.src];

    if (file === undefined) {
      return;
    }

    const audioData = await file.arrayBuffer();

    // formatted to suits the xhrloader response that was done first
    return super.fileLoad({ target: { response: audioData } });
  }
}
