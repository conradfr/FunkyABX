import EventEmitter from 'eventemitter3';
import devices from '../utils/devices';

/* eslint-disable no-undef */
const OutputSelectorHook = {
  mounted() {
    // ---------- INIT ----------

    this.ee = new EventEmitter();
    // LiveView will close open Bootstrap dropdown on update so we track state to restore it
    this.restoreDeviceSelectorDropdownShow = false;

    // ---------- SERVER EVENTS ----------

    this.handleEvent('select_output', async () => {
      const devicesList = await devices.listDevices();
      this.pushEventTo(this.el, 'output_devices', { devices: devicesList });
    });
  },
  beforeUpdate() {
    const outputSelectorDropdownElem = document.getElementById('output-selector-dropdown');
    if (outputSelectorDropdownElem && outputSelectorDropdownElem.classList.contains('show')) {
      this.restoreDeviceSelectorDropdownShow = true;
    } else {
      this.restoreDeviceSelectorDropdownShow = false;
    }
  },
  updated() {
    if (this.restoreDeviceSelectorDropdownShow === true) {
      const outputSelectorDropdownElem = document.getElementById('output-selector-dropdown');
      const outputSelectorDropdown = bootstrap.Dropdown.getInstance(outputSelectorDropdownElem);
      outputSelectorDropdown.show();
    }
  },
  /* updated() {
    console.log("editor update...")
  } */
};

export default OutputSelectorHook;
