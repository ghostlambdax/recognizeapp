window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["recognitions-index"] = function() {
  rLog('Start streaming', window.R.ui.Stream);
  return new window.R.ui.Stream();
};
