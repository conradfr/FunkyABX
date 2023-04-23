const TOAST_DURATION = 3500;

/* eslint-disable no-undef */
const BsToastHook = {
  mounted() {
    this.handleEvent('show_toast', ({ id }) => {
      const toastElem = document.getElementById(id);
      if (toastElem) {
        const toast = new bootstrap.Toast(toastElem, {delay: TOAST_DURATION});
        toast.show();

        setTimeout(
          () => {
            toast.hide();
            this.pushEventTo(this.el, 'toast_closed', { id });
          },
          TOAST_DURATION + 500
        );
      }
    });
  }
};

export default BsToastHook;
