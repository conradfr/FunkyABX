/* eslint-env browser */

import { lufs, truepeak } from '@audio/loudness';

/*
  Loudness analysis of a decoded track (EBU R128 / ITU-R BS.1770), done in the browser for local tests.
  Same shape as the server side analysis (FunkyABX.Analyzer.Loudness), a value is null when it can't be
  measured (silence, file shorter than 400ms ...).
 */
export default function analyzeLoudness(audioBuffer) {
  if (!audioBuffer) {
    return null;
  }

  try {
    const fs = audioBuffer.sampleRate;
    const channels = [];
    for (let c = 0; c < audioBuffer.numberOfChannels; c++) {
      channels.push(audioBuffer.getChannelData(c));
    }

    const integrated = lufs(channels, { fs });
    const truePeak = truepeak(channels, { fs });

    return {
      integrated: Number.isFinite(integrated) ? integrated : null,
      true_peak: Number.isFinite(truePeak) ? truePeak : null
    };
  } catch (e) {
    console.warn('Loudness analysis error', e);
    return null;
  }
}
