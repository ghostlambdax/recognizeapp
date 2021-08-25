(function() {
  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.AccessToken = AccessToken;

  function AccessToken(token) {
    this.token = token || "";

    return token;
  };

  AccessToken.prototype.clear = function() {
    Recognize.patterns.storage.set("auth", false);
    this.token = "";
  };

})();

