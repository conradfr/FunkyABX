/* eslint-env browser */

// Inspired by https://github.com/meandavejustice/draw-wave

export default class {
  constructor(canvas, buffer, trackWidthPercent) {
    this.canvas = canvas;
    this.buffer = buffer;
    this.trackWidthPercent = trackWidthPercent;

    this.barWidth = 2;
    this.barSpace = 1;
    this.color = 'white';
    this.colorPast = '#888';
    this.colorPastActive = '#40A8BDFF';

    this.width = Math.round((trackWidthPercent * canvas.width) / 100);
    this.amp = canvas.height / 2;
    this.nbOfBars = Math.round(this.width / (this.barWidth + this.barSpace));

    this.audioData = buffer.getChannelData(0);
    this.nbPointsPerBar = Math.round(this.audioData.length / this.nbOfBars);
    // we calculate bars coordinates only once
    this.pixelData = this.generateData();

    this.lastCurrentPixel = 0;
    this.lastCurrentBar = 0;
  }

  draw(currentPixel, active) {
    const ctx = this.canvas.getContext('2d');
    const currentBar = Math.round(currentPixel / (this.barWidth + this.barSpace));

    let clearXStart = 0;
    let clearXEnd = this.pixelData.length - 1;

    if (currentBar > this.lastCurrentBar) {
      clearXStart = Math.max(0, this.lastCurrentBar);
      clearXEnd = Math.min(currentBar, this.pixelData.length - 1);
    } else if (currentBar < this.lastCurrentBar) {
      clearXStart = Math.max(0, currentBar);
      clearXEnd = Math.min(this.lastCurrentBar, this.pixelData.length - 1);
    }

    ctx.clearRect(
      clearXStart * (this.barWidth + this.barSpace),
      0,
      ((clearXEnd - 1) * (this.barWidth + this.barSpace))
        - (clearXStart * (this.barWidth + this.barSpace)),
      this.canvas.height
    );

    for(let i = clearXStart; i <= clearXEnd; i += 1) {
      const x = this.pixelData[i][0];
      if (x <= currentPixel) {
        ctx.fillStyle = active === true ? this.colorPastActive : this.colorPast;
      } else {
        ctx.fillStyle = this.color;
      }

      ctx.fillRect(
        x,
        this.pixelData[i][1],
        this.pixelData[i][2],
        this.pixelData[i][3]
      );
    }

    this.lastCurrentPixel = currentPixel;
    this.lastCurrentBar = currentBar;
  }

  generateData() {
    const pixelData = [];

    for(let i = 0; i <= this.nbOfBars; i += 1) {
      let min = 1.0;
      let max = -1.0;
      for (let j = 0; j < this.nbPointsPerBar; j += 1) {
        const datum = this.audioData[(i * this.nbPointsPerBar) + j];
        if (datum < min) {
          min = datum;
        }

        if (datum > max) {
          max = datum;
        }
      }

      const x = i * (this.barWidth + this.barSpace) - this.barWidth;

      pixelData.push([
        x,
        (1 + min) * this.amp,
        this.barWidth,
        Math.max(1, (max - min) * this.amp)
      ]);
    }

    return pixelData;
  }
}
