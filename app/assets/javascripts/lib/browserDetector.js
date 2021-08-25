window.R = window.R || {};
window.R.utils = window.R.utils || {};

window.R.utils.browserDetector = function() {
  var browser;

  if (navigator.userAgent.match(/(iPhone|iPod|iPad)/i)) {
      browser = "ios";
      Modernizr.ios = true;
  } else if (navigator.userAgent.match(/(Android|android)/i)) {
      Modernizr.android = true;
      $html.addClass('android');
      browser = "android";
  } else if ($("body > div#ie").length > 0 || "ActiveXObject" in window) {
      Modernizr.ie = true;
      browser = "ie";
  } else if (jQuery && jQuery.browser && jQuery.browser.chrome) {
      browser = "chrome";
  } else if (jQuery && jQuery.browser && jQuery.browser.mozilla) {
      browser = "firefox";
  } else if (jQuery && jQuery.browser && jQuery.browser.safari) {
      browser = "safari";
  } else if (navigator.userAgent.match(/(Android|android)/i)) {
      Modernizr.android = true;
      $html.addClass('android');
      browser = "android";
  }

  window.R.utils.browserDetector.browser = browser;

  $html.addClass(browser);
};
