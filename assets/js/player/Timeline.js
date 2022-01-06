/* eslint-env browser */

export default class {
  constructor(canvas, drawWaveformUnder, buffer, trackWidthPercent) {
    this.canvas = canvas;
    this.buffer = buffer;
    this.trackWidthPercent = trackWidthPercent;
    this.drawWaveformUnder = drawWaveformUnder;

    this.width = Math.round((trackWidthPercent * canvas.width) / 100);
    this.audioData = buffer.getChannelData(0);

    // Waveform
    if (this.drawWaveformUnder === true) {
      this.canvasWaveform = document.createElement('canvas');
      this.canvasWaveform.width = this.canvas.width;
      this.canvasWaveform.height = this.canvas.height;

      this.barWidth = 2;
      this.barSpace = 1;
      this.color = '#353535';
      this.colorActive = '#0e778c';
      this.colorPast = '#333333';
      this.colorPastActive = '#0c758a';

      this.amp = canvas.height / 2;
      this.nbOfBars = Math.round(this.width / (this.barWidth + this.barSpace));

      this.nbPointsPerBar = Math.round(this.audioData.length / this.nbOfBars);
      // we calculate bars coordinates only once
      this.pixelData = this.generateData();
    }

    // Timeline
    this.tlColor = 'white';
    this.tlColorPast = '#888';
    this.tlColorPastActive = '#40A8BDFF';

    this.seconds = Math.round(this.audioData.length / buffer.sampleRate);
    this.nbPixelsPerSecond = Math.round(this.width / this.seconds);

    this.lastCurrentPixel = 0;
    this.lastCurrentBar = 0;
    this.isActive = false;
  }

  draw(currentPixel, active) {
    const ctx = this.canvas.getContext('2d');

    if (this.drawWaveformUnder === true) {
      const ctxWaveform = this.canvasWaveform.getContext('2d');
      this.drawWaveform(currentPixel, active, ctxWaveform);
      ctx.drawImage(this.canvasWaveform, 0, 0);

    }

    ctx.clearRect(
      0,
      0,
      this.width,
      this.canvas.height
    );

    if (this.drawWaveformUnder === true) {
      ctx.drawImage(this.canvasWaveform, 0, 0);
    }

    this.drawTimeline(currentPixel, active, ctx);
    this.isActive = active;
  }

  // ---------- WAVEFORM ----------

  drawWaveform(currentPixel, active, ctx) {
    if (active !== this.isActive) {
      ctx.clearRect(
        0,
        0,
        this.width,
        this.canvas.height
      );
    }

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

    if (active !== this.isActive) {
      ctx.clearRect(
        0,
        0,
        this.width,
        this.canvas.height
      );
    } else {
      ctx.clearRect(
        clearXStart * (this.barWidth + this.barSpace),
        0,
        ((clearXEnd - 1) * (this.barWidth + this.barSpace))
        - (clearXStart * (this.barWidth + this.barSpace)),
        this.canvas.height
      );
    }

    for(let i = clearXStart; i <= clearXEnd; i += 1) {
      const x = this.pixelData[i][0];
      if (x <= currentPixel) {
        ctx.fillStyle = active === true ? this.colorPastActive : this.colorPast;
      } else {
        // ctx.fillStyle = this.color;
        ctx.fillStyle = active === true ? this.colorActive : this.color;
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

  // ---------- TIMELINE ----------

  drawTimeline(currentPixel, active, ctx) {
    const pastColor = active ? this.tlColorPastActive : this.tlColorPast;

    // ctx.clearRect(
    //   0,
    //   0,
    //   this.width,
    //   this.canvas.height
    // );

    // horizontal

    // past
    if (currentPixel > 0) {
      this.drawHorizontalBar(0, Math.min(currentPixel, this.width), pastColor, 3, ctx);
    }

    if (currentPixel < this.width) {
      this.drawHorizontalBar(currentPixel, this.width, this.tlColor, 1, ctx);
    }

    //vertical

    let y = 5;

    for(let i = 0; i <= this.seconds; i += 5) {
      // FizzBuzz!
      if (i % 30 === 0) {
        y = 7;
      } else if (i % 15 === 0) {
        y = 14;
      } else if (i % 5 === 0) {
        y = 18;
      } else {
        y = 20;
      }

      const barColor = i * this.nbPixelsPerSecond < currentPixel ? pastColor : this.tlColor;
      this.drawVerticalBar(i, y, barColor, ctx);

      ctx.fillStyle = barColor;

      if (y === 7) {
        ctx.font = '10px serif';
        ctx.fillText(this.formatTime(i), i * this.nbPixelsPerSecond + 7, 8);
      } /*else if (y === 15) {
        ctx.font = '9px serif';
        ctx.fillText(this.formatTime(i), i * this.nbPixelsPerSecond - 4, 40);
      }*/
    }
  }

  drawHorizontalBar(from, to, color, width, ctx) {
    // const heightAdjustment = height === 1 ? 0 : (height / 2);
    const heightAdjustment = 0;

    ctx.beginPath();
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    ctx.moveTo(from, this.canvas.height / 2 - heightAdjustment);
    ctx.lineTo(to, this.canvas.height / 2 - heightAdjustment);
    ctx.stroke();
  }

  drawVerticalBar(x, y, color, ctx) {
    ctx.beginPath();
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.moveTo(x * this.nbPixelsPerSecond + 1, y);
    ctx.lineTo(x * this.nbPixelsPerSecond + 1, this.canvas.height - y);
    ctx.stroke();
  }

  formatTime(seconds) {
    const sec_num = parseInt(seconds, 10);
    const hours = Math.floor(sec_num / 3600);
    const minutes = Math.floor(sec_num / 60) % 60;
    seconds = sec_num % 60;

    let text = '';

    if (hours > 0) {
      text += `${hours.toString().padStart(2, '0')}:`;
    }

    text += `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

    return text;
  }
}
