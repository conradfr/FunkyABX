// @note from https://www.yellowduck.be/posts/making-your-phoenix-flash-messages-disappear-automatically

const delayMs = 2500

export default {
  mounted() {
    setTimeout(() => {
      this.el.style.transition = 'opacity 0.5s'
      this.el.style.opacity = '0'
      setTimeout(() => this.el.remove(), 500)
    }, delayMs)
  },
};
