/* eslint-disable no-undef */
const GlobalHook = {
  mounted() {
    this.warningReload = (e) => {
      e.preventDefault();
      // the text is useless
      return 'Are you sure you want to leave/reload the page? Tracks will be lost.';
    };

    this.handleEvent('set_warning_local_test_reload', (params) => {
      if (params.set === false && this.preventReloadSet === true) {
        this.preventReloadSet = false;
        window.removeEventListener('beforeunload', this.warningReload);
        return;
      }

      if (params.set === true && this.preventReloadSet !== true) {
        this.preventReloadSet = true;
        window.addEventListener('beforeunload', this.warningReload);
      }
    });
  },
  destroyed() {
    if (this.preventReloadSet === true) {
      window.removeEventListener('beforeunload', this.warningReload);
    }
  }
};

export default GlobalHook;
