import Sortable from 'sortablejs'

// Drag & drop reordering of the tracks in the test form.
// Sortable only moves the DOM, the new order is sent to the server which re-renders the list.
const SortableTracksHook = {
  mounted() {
    this.sortable = Sortable.create(this.el, {
      handle: '.track-drag-handle',
      draggable: '.track-sortable-item',
      animation: 150,
      ghostClass: 'track-sortable-ghost',
      disabled: this.isDisabled(),
      onEnd: (evt) => {
        if (evt.oldIndex === evt.newIndex) {
          return
        }

        const ids = Array.from(this.el.querySelectorAll(':scope > .track-sortable-item'))
          .map((el) => el.dataset.trackId)
          .filter((id) => id !== undefined && id !== '')

        this.pushEvent('reorder_tracks', { ids })
      },
    })
  },
  updated() {
    this.sortable.option('disabled', this.isDisabled())
  },
  destroyed() {
    if (this.sortable) {
      this.sortable.destroy()
      this.sortable = null
    }
  },
  isDisabled() {
    return this.el.dataset.disabled === 'true'
  },
}

export default SortableTracksHook
