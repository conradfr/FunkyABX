/* eslint-env browser */

export const COOKIE_PREFIX = 'funkyabx_';
export const COOKIE_TTL = '31536000';
export const COOKIE_PARAMS = {
  path: '/',
  'max-age': COOKIE_TTL,
  expires: 'mage-age',
  secure: true,
  SameSite: 'Lax'
};

export const COOKIE_TEST_TAKEN = `${COOKIE_PREFIX}test_taken`;
export const COOKIE_TEST_BYPASS = `${COOKIE_PREFIX}test_bypass`;
export const COOKIE_TEST_AUTHOR = `${COOKIE_PREFIX}test_author`;
export const COOKIE_TEST_ROTATE_SECONDS = `${COOKIE_PREFIX}rotate_seconds`;
export const COOKIE_TEST_ROTATE = `${COOKIE_PREFIX}rotate`;
export const COOKIE_TEST_WAVEFORM = `${COOKIE_PREFIX}waveform`;
