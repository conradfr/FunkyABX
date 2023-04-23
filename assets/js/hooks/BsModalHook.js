/* eslint-disable no-undef */
const BsModalHook = {
  mounted() {
    this.modal = null;
    const id = this.el.dataset.id;

    this.open = (_event) => {
/*      if (event.detail.id !== id) {
        return;
      }*/

      this.modal = new bootstrap.Modal(`#${id}`);
      this.modal.show();
    };

    this.close = () => {
      this.modal.hide();
    };

    window.addEventListener('open_modal', this.open);
    window.addEventListener('close_modal', this.close);
  },
  destroyed() {
    if (this.modal !== null) {
      this.modal.dispose();
    }

    window.removeEventListener('open_modal', this.open);
    window.removeEventListener('close_modal', this.close);
  }
};

export default BsModalHook;
