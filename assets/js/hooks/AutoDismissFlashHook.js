// @note from https://www.yellowduck.be/posts/making-your-phoenix-flash-messages-disappear-automatically

const delayMs = 2500

export default {
  mounted() {
    setTimeout(() => {
      this.el.style.transition = 'opacity 0.5s'
      this.el.style.opacity = '0'
      // clears the flash server side too: otherwise the same message put again later is not
      setTimeout(() => this.pushEvent('lv:clear-flash', { key: this.el.dataset.kind }), 500)
    }, delayMs)
  },
};
