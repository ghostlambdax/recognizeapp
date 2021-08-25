window.R = window.R || {};

window.R.Select2 = (function($, window, body, R, undefined) {
  var Select2 = function(callback) {
    if(typeof($('select').select2) === 'function') {
      if (callback) {
        callback();
      }
    } else {
      $('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', 'https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.0/css/select2.min.css') );
      $.cachedScript('https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.0/js/select2.min.js').done(function() {
        if (callback) {
          callback();
        }
      });
    }

  };

  return Select2;

})(jQuery, window, document.body, window.R);

// `cachedScript()` is an alternative to the `getScript()` method. See: https://api.jquery.com/jquery.getscript/.
// `cachedScript()` fetches and caches the script, whereas `getScript()` doesn't cache but fetches everytime.
jQuery.cachedScript = function( url, options ) {
  // Allow user to set any option except for dataType, cache, and url
  options = $.extend( options || {}, {
    dataType: "script",
    cache: true,
    url: url
  });

  // Use $.ajax() since it is more flexible than $.getScript
  // Return the jqXHR object so we can chain callbacks
  return jQuery.ajax( options );
};