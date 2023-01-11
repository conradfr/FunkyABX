import XHRLoader from './XHRLoader';
// import IndexDBLoader from './IndexDBLoader';
import StoredFileLoader from './StoredFileLoader';

export default class {
  static createLoader(trackInfo, ac, ee, audioFiles) {
    if (trackInfo.local === false && typeof trackInfo.url === 'string') {
      return new XHRLoader(trackInfo.hash, trackInfo.url, ac, ee);
    }

    /* if (trackInfo.local === true) {
      return new IndexDBLoader(trackInfo.id, ac, ee, fileHandles);
    } */

    if (trackInfo.local === true) {
      return new StoredFileLoader(trackInfo.hash, trackInfo.id, ac, ee, audioFiles);
    }

    throw new Error('Unsupported src type');
  }
}
