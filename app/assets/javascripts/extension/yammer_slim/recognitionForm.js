(function() {
  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.recognitionForm = {
    open: open,
    close: Recognize.patterns.overlay.close
  };

  var template;

  function open() {
    Recognize.utils.openWindow(Recognize.path("redirect/recognitions/new_chromeless"), 600, 650);
  }

})();
