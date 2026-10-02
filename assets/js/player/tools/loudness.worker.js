/* eslint-env worker */

// Web worker entry point (built separately, see build.js): analyzes one track per message.

import analyzeLoudness from './loudness';

self.onmessage = (e) => {
  const { id, channels, sampleRate } = e.data;
  self.postMessage({ id, loudness: analyzeLoudness(channels, sampleRate) });
};
