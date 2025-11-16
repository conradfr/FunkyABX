import cookies from '../utils/cookies';
import {
  COOKIE_COMMENT_AUTHOR,
} from '../config/config';

/* eslint-disable no-undef */
const CommentsHook = {
  mounted() {
    // ---------- INIT ----------

    if (cookies.has(COOKIE_COMMENT_AUTHOR)) {
      this.pushEventTo(this.el, 'comment_author', { author: cookies.get(COOKIE_COMMENT_AUTHOR) });
    }

    // ---------- SERVER EVENTS ----------

    this.handleEvent('save_comment_author', (params) => {
      cookies.set(COOKIE_COMMENT_AUTHOR, params.author);
    });
  },
};

export default CommentsHook;
