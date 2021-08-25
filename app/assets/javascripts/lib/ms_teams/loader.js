window.R = window.R || {};

window.R.msTeams.Loader = (function($, window, body, R, undefined) {
  var MsTeams = function(callback) {
    if(typeof(window.R.microsoftTeams) === 'function') {
      init(callback);
    } else {
      $.cachedScript('https://statics.teams.cdn.office.net/sdk/v1.5.2/js/MicrosoftTeams.min.js').done(function() {

        window.R.msTeams = window.R.msTeams || {};
        window.R.msTeams.client = microsoftTeams;
    
        window.R.msTeams.client.initialize();
        init(callback);

      });
    }

  };

  function init(callback) {
    window.R.msTeams.client.getContext(function(context){
      window.R.msTeams.context = context;
      if(callback) {
        callback();
      }
    });
  }


  return MsTeams;

})(jQuery, window, document.body, window.R);

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
