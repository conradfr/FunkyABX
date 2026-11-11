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

// a pointer move shorter than this (px) on a waveform is a click (seek), a longer one drags a cue
export const CUE_DRAG_THRESHOLD_PX = 4;
// distance (px) from an edge of the cue at which it can be grabbed to adjust it
export const CUE_EDGE_GRAB_PX = 5;
// shortest cue (seconds) a drag can create, a shorter drag is cancelled
export const CUE_MIN_DURATION_SECONDS = 0.1;
