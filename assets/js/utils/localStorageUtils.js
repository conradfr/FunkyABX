/* eslint-env browser */

// http://crocodillon.com/blog/always-catch-localstorage-security-and-quota-exceeded-errors
const clearIfFull = (e) => {
  let quotaExceeded = false;
  if (e) {
    if (e.code) {
      switch (e.code) {
        case 22:
          quotaExceeded = true;
          break;
        case 1014:
          // Firefox
          if (e.name === 'NS_ERROR_DOM_QUOTA_REACHED') {
            quotaExceeded = true;
          }
          break;
        default:
        // nothing
      }
    } else if (e.number === -2147024882) {
      // Internet Explorer 8
      quotaExceeded = true;
    }
  }

  if (quotaExceeded === true) {
    localStorage.clear();
  }
};


export default {
  clearIfFull
};
