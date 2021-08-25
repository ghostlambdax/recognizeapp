(function() {
  Recognize = Recognize || {};
  Recognize.patterns.File = File;

  function File() {};

  File.prototype.getPath = function(file) {
    return Recognize.host+"/assets/extension/yammer/"+file;
  };

  File.prototype.load = function(path) {
    var div = jQuery("<div>");
    div.load(Recognize.file.getPath(path));
    $body.append(div);
  }
  
})();

