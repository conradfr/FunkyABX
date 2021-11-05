import XHRLoader from './XHRLoader';

export default class {
  static createLoader(src, ac, ee) {
    if (typeof src === 'string') {
      return new XHRLoader(src, ac, ee);
    }

    throw new Error('Unsupported src type');
  }
}
