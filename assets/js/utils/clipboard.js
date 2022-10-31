const copy = (text) => {
  /* eslint-disable no-undef */
  navigator.clipboard.writeText(text);
};

export default {
  copy
};
