(function() {

  Recognize = Recognize || {};

  Recognize.ajax = function(userOptions) {
    var options = {
      xhrFields: {
        withCredentials: true
      },
      crossDomain: true,
      contentType: "text/plain"
    };

    // if (Recognize.accessToken) {
    //   options.headers = {
    //     'Authorization': 'Bearer ' + Recognize.accessToken()
    //   }
    // } else {
    //   options.headers = {
    //     'X-Authorization-Cookie-Auth': 'true'
    //   }
    // }

    if( userOptions) {
      jQuery.extend(options, userOptions);      
    }

    return jQuery.ajax(options);
  };
})();
