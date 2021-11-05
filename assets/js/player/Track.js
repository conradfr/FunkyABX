
export default class {
  constructor(src, buffer, ac, ee) {
    this.src = src;
    this.buffer = buffer;
    this.ac = ac;
    this.ee = ee;
    this.gainNode = null;
    this.active = false;
    this.source = null;
  }

  setActive(active) {
    if (this.source !== null && this.gainNode !== null) {
      this.gainNode.gain.value = active ? 1 : 0;
    }

    this.active = active;
  }

  getDuration() {
    if (this.buffer === null) {
      return 0;
    }

    return this.buffer.duration;
  }

  cleanSource() {
    if (this.gainNode !== null) {
      this.gainNode.disconnect();
      this.gainNode = null;
    }

    if (this.source !== null) {
      this.source.disconnect();
      this.source = null;
      this.ee.emit('stopping', this.src.hash);
    }
  }

  schedulePlay(now, startTime, endTime, config) {
    this.source = this.ac.createBufferSource();
    this.source.buffer = this.buffer;

    this.gainNode = this.ac.createGain();
    this.source.connect(this.gainNode);
    this.gainNode.connect(this.ac.destination);
    this.gainNode.gain.value = this.active ? 1 : 0;

    const sourcePromise = new Promise((resolve) => {
      // keep track of the buffer state.
      this.source.onended = () => {
        this.cleanSource();
        resolve();
      };
    });
    
    this.source.start(0);
    this.ee.emit('playing', this.src.hash);

    return sourcePromise;
  }
  stop() {
    this.source.stop();
    this.cleanSource();
  }
}
