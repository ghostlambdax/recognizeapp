(function() {
  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.recognitionForm = {
    open: open,
    close: Recognize.patterns.overlay.close
  };

  var template;

  function open(yammerId, message) {
    var that = this;

    template = template || Handlebars.compile(jQuery('#r-iframe').html());

    getModalURL(yammerId, message, function(data) {

     var iframeHTML = template({
      url: data.url,
      id: 'r-recognition-new-iframe'
    });

     Recognize.patterns.overlay.open(Recognize.patterns.i18n().send_recognition, iframeHTML);
   });

  }

  function getModalURL(yammerId, message, callback) {
    var url = '/recognitions/new', params = {viewer: "yammer"};

    if (yammerId) {
      params["yammer_id"] = yammerId;
    }

    if (message) {
      params["message"] = message;
    }

    if( yammerId || message) {
      url = url + "?" + jQuery.param(params);
    }
    
    var gettingModalUrl = Recognize.patterns.api.get(url);
    gettingModalUrl.done(callback);
  }
})();
