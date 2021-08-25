Recognize = Recognize || {};
Recognize.utils = Recognize.utils || {};

Recognize.utils.getParameterByName = function( name, href ) {
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( href );
  if( results == null )
    return "";
  else
    return decodeURIComponent(results[1].replace(/\+/g, " "));
}

Recognize.utils.showAuthorizationHeader = function() {
  Recognize.patterns.toolbar.create(false);
};


Recognize.utils.openWindow = function(url, width, height, callback) {
  var popup, status;
  width = width || 1024;
  height = height || 768;

  console.log("url", url);

  if (window.Office) {
    popup = Office.context.ui.displayDialogAsync(url,
        {height: 90, width: 55, requireHTTPS: true},
        function (result) {
          if (callback) callback(result);
        });
  } else {
    popup = window.open(url, '_blank', 'location=yes,height='+height+',width='+width+',scrollbars=yes,status=yes');
    if (popup) {
      status = "succeeded";
    } else {
      status = "failed";
    }

    if (callback) {
      callback({value: popup, status: status});
    }
  }

  return popup;
};