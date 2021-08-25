window.R = window.R || {};
window.hasTouch = 'ontouchstart' in window;

R.ui = R.ui || {};

R.nameSpace = function() {
  window.R.touchEvent = (window.hasTouch) ? "tap" : "click";

  window.body = document.body;
  window.$body = $(document.body);

  window.$window = window.$window || $(window);
  window.$html = window.$html || $("html");
  window.$document = window.$document || $(document);
  window.R.host = window.localStorage.recognizeHost || (typeof(gon) !== 'undefined' ? gon.recognize_host : "https://recognizeapp.com");
};

R.nameSpace();

R.defaultAvatarPath = "icons/user-default.png";
