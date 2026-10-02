import { lufs, truepeak } from '@audio/loudness';

/*
  Loudness analysis of a decoded track (EBU R128 / ITU-R BS.1770), done in the browser for local tests.
  Same shape as the server side analysis (FunkyABX.Analyzer.Loudness), a value is null when it can't be
  measured (silence, file shorter than 400ms ...).
  Runs in a web worker (loudness.worker.js), it receives the channels data as an AudioBuffer can't be posted.
 */
export default function analyzeLoudness(channels, sampleRate) {
  if (!channels || channels.length === 0) {
    return null;
  }

  try {
    const integrated = lufs(channels, { fs: sampleRate });
    const truePeak = truepeak(channels, { fs: sampleRate });

    return {
      integrated: Number.isFinite(integrated) ? integrated : null,
      true_peak: Number.isFinite(truePeak) ? truePeak : null
    };
  } catch (e) {
    console.warn('Loudness analysis error', e);
    return null;
  }
}
