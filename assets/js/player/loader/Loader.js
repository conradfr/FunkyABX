export const STATE_UNINITIALIZED = 'loading';
export const STATE_LOADING = 'loading';
export const STATE_DECODING = 'decoding';
export const STATE_FINISHED = 'finished';
export const STATE_ERROR = 'error';

export default class {
  constructor(hash, src, ac, ee, audioFiles) {
    this.hash = hash;
    this.src = src;
    this.ac = ac;
    this.audioRequestState = STATE_UNINITIALIZED;
    this.ee = ee;
    this.audioFiles = audioFiles;
  }

  setStateChange(state) {
    this.audioRequestState = state;
    this.ee.emit('audiorequeststatechange', {
      track_hash: this.hash,
      state: this.audioRequestState
    });
  }

  fileProgress(e) {
    let percentComplete = 0;

    if (this.audioRequestState === STATE_UNINITIALIZED) {
      this.setStateChange(STATE_LOADING);
    }

    if (e.lengthComputable) {
      percentComplete = (e.loaded / e.total) * 100;
    }

    this.ee.emit('loadprogress', {track_hash: this.hash, progress: percentComplete});
  }

  fileLoad(e) {
    const audioData = e.target.response || e.target.result;

    this.setStateChange(STATE_DECODING);

    return new Promise((resolve, reject) => {
      this.ac.decodeAudioData(
        audioData,
        (audioBuffer) => {
          this.audioBuffer = audioBuffer;
          this.setStateChange(STATE_FINISHED);

          resolve(audioBuffer);
        },
        (err) => {
          this.setStateChange(STATE_ERROR);
          if (err === null) {
            // Safari issues with null error
            reject(Error('MediaDecodeAudioDataUnknownContentType'));
          } else {
            reject(err);
          }
        }
      );
    });
  }
}
