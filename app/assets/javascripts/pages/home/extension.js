window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["home-extension"] = (function($, window, undefined) {
  function T() {
    T.superclass.constructor.apply(this, arguments);
  }

  R.utils.inherits(T, R.pages.home);

  T.prototype.addEvents = function() {
    T.superclass.addEvents.apply(this);
  };

  T.prototype.removeEvents = function() {
    T.superclass.removeEvents.apply(this);
  };

  return T;
})(jQuery, window);