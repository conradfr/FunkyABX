/* eslint-env browser */

// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import '../css/app.scss';

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

// ---------- TEMP ----------
// adapted from ChatGPT

import { COOKIE_TTL } from './config/config';

let cookies = document.cookie.split(';');
let renamed = false;

for (let i = 0; i < cookies.length; i++) {
  let cookie = cookies[i];
  let eqPos = cookie.indexOf('=');
  let name = eqPos > -1 ? cookie.substr(0, eqPos).trim() : cookie.trim();

  let newName = '';
  let value = '';

  if (name.startsWith('funkyabx_test_')) {
    newName = name.substring('funkyabx_test_'.length);
    value = eqPos > -1 ? cookie.substr(eqPos + 1) : '';

    if (!newName.endsWith('_tracks_order')) {
      document.cookie = newName + "=" + value + `;expires=${COOKIE_TTL};path=/`;
    }

    // Delete the old cookie
    document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;";

    renamed = true;
  } else if (name.startsWith('funkyabx_')) {
    newName = name.substring('funkyabx_'.length);
    value = eqPos > -1 ? cookie.substr(eqPos + 1) : "";
    document.cookie = newName + "=" + value + ";path=/";

    // Delete the old cookie
    document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;";

    renamed = true;
  } else if (name.endsWith('_tracks_order')) {
    document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;";
  }
}

if (renamed === true) {
  location.reload();
}

// ---------- END TEMP ----------

// App hooks
import BsToastHook from './hooks/BsToastHook';
import BsModalHook from './hooks/BsModalHook';
import GlobalHook from './hooks/GlobalHook';
import TestHook from './hooks/TestHook';
import LocalTestFormHook from './hooks/LocalTestFormHook';
import TestFormHook from './hooks/TestFormHook';
import TestResultsHook from './hooks/TestResultsHook';
import PlayerHook from './hooks/PlayerHook';

const audioFiles = {};
const Hooks = {};

Hooks.BsToast = BsToastHook;
Hooks.BsModal = BsModalHook;
Hooks.Global = GlobalHook;
Hooks.Test = TestHook;
Hooks.LocalTestForm = LocalTestFormHook;
Hooks.TestForm = TestFormHook;
Hooks.TestResults = TestResultsHook;
Hooks.Player = PlayerHook;

/*
  Audio files need to be global as some browser needs them to come from user action
  and so can't be restored between pages/hooks.
 */
Hooks.Player.setAudioFiles(audioFiles);
Hooks.LocalTestForm.setAudioFiles(audioFiles);
Hooks.TestResults.setAudioFiles(audioFiles);

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')
const liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks,
  params: {
    _csrf_token: csrfToken,
    page_id: Math?.floor(Math.random() * 100000000000000000000),
    locale: Intl.NumberFormat().resolvedOptions().locale,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
  }
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: {0: '#29d'}, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', _info => topbar.show(300));
window.addEventListener('phx:page-loading-stop', _info => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

