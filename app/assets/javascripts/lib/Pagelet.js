window.R = window.R || {};

window.R.Pagelet = (function($, window, body, R, undefined) {
  var pageletLoadedCssClass = "pagelet-loaded";

  var Pagelet = function(callback) {
    this.callback = callback || function() {};
    this.addEvents();
  };

  Pagelet.prototype.addEvents = function() {
    $(".pagelet").each(function(index, el) {
      // Only load if hasn't already loaded content.
      if ( !$(el).hasClass(pageletLoadedCssClass) ) {
        this.getPagelet(el);
      }
    }.bind(this));
  };

  Pagelet.prototype.getPagelet = function(pageletDiv) {
    var $pagelet = $(pageletDiv);
    var endpoint = $pagelet.data("endpoint");
    $pagelet.load(endpoint, function() {
      $pagelet.addClass(pageletLoadedCssClass);
      $pagelet.trigger("pageletLoaded");
      this.callback(pageletDiv);
    }.bind(this));
  };

  return Pagelet;

})(jQuery, window, document.body, window.R);