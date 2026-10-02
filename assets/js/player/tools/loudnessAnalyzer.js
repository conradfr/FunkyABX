/* eslint-env browser */

import analyzeLoudness from './loudness';

// Built next to app.js by build.js
const WORKER_FILE = 'workers/loudness.js';

/*
  Analyzes the loudness of decoded tracks in a web worker so the page doesn't freeze.
  Resolves with one loudness result (or null) per audio buffer, in the same order.
  If the worker can't be used, the analysis is done on the main thread instead.
 */
export default function analyzeTracksLoudness(audioBuffers) {
  return new Promise((resolve) => {
    let worker;
    try {
      worker = new Worker(workerUrl());
    } catch (e) {
      console.warn('Loudness worker unavailable, analyzing on main thread', e);
      resolve(analyzeOnMainThread(audioBuffers));
      return;
    }

    const results = audioBuffers.map(() => null);
    let pending = 0;

    const done = () => {
      worker.terminate();
      resolve(results);
    };

    worker.onmessage = (e) => {
      results[e.data.id] = e.data.loudness;
      pending -= 1;
      if (pending === 0) {
        done();
      }
    };

    // also triggered when the worker script fails to load
    worker.onerror = (e) => {
      console.warn('Loudness worker error, analyzing on main thread', e);
      worker.terminate();
      resolve(analyzeOnMainThread(audioBuffers));
    };

    audioBuffers.forEach((audioBuffer, id) => {
      if (!audioBuffer) {
        return;
      }

      pending += 1;
      // channels are copied (structured clone), the audio buffer is left untouched for playback
      worker.postMessage({ id, channels: getChannels(audioBuffer), sampleRate: audioBuffer.sampleRate });
    });

    if (pending === 0) {
      done();
    }
  });
}

function analyzeOnMainThread(audioBuffers) {
  return audioBuffers.map((audioBuffer) => audioBuffer
    ? analyzeLoudness(getChannels(audioBuffer), audioBuffer.sampleRate)
    : null);
}

function getChannels(audioBuffer) {
  const channels = [];
  for (let c = 0; c < audioBuffer.numberOfChannels; c++) {
    channels.push(audioBuffer.getChannelData(c));
  }

  return channels;
}

// Same folder and cache busting query string as app.js
function workerUrl() {
  const appScript = document.querySelector('script[src*="/assets/app.js"]');
  const url = new URL(appScript ? appScript.src : '/assets/app.js', window.location.href);
  url.pathname = url.pathname.replace(/app\.js$/, WORKER_FILE);

  return url.toString();
}
