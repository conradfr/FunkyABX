/* eslint-env browser */

// ---------- COOKIES ----------

export const COOKIE_TTL = '31536000';
export const COOKIE_PARAMS = {
  path: '/',
  'max-age': COOKIE_TTL,
  expires: 'mage-age',
  secure: true,
  SameSite: 'None'
};

export const COOKIE_TEST_TAKEN = 'taken';
export const COOKIE_TEST_BYPASS = 'bypass';
export const COOKIE_TEST_AUTHOR = 'author';
export const COOKIE_COMMENT_AUTHOR = 'comment-author';
export const COOKIE_TEST_ROTATE_SECONDS = 'rotate_seconds';
export const COOKIE_TEST_ROTATE = 'rotate';
export const COOKIE_TEST_WAVEFORM = 'waveform';
export const COOKIE_VOLUME = 'test-volume';
export const COOKIE_DEVICE = 'player-device';

// ---------- CUE ----------

export const CUE_OVER_TOLERANCE = 3;
