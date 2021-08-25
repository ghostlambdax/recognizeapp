(function() {
  'use strict';

  window.R = window.R || {};

  window.R.Integrations = I;

  function I(success) {
    this.addEvents();
    this.success = success || this.defaultSuccess;
  }

  I.prototype.defaultSuccess = function() {
    Swal.fire({
      icon: "success",
      showConfirmButton: false
    });
    window.location = "/";
  };

  I.prototype.addEvents = function() {
    if (window.location.search.indexOf("viewer") > -1 && window.location.search.indexOf("mobile") == -1) {

      // Can't bind to $document to prevent default UJS link behavior
      // https://github.com/rails/jquery-rails/issues/151#issuecomment-34601652
      var selector = ".login-wrapper > .button, .o365-auth-link, .button-yammer-plain";
      $(selector).on(R.touchEvent, function(e){ 
        e.preventDefault();
        e.stopPropagation();

        this.auth(e);

        return false;
      }.bind(this));
      
    }
  };

  I.prototype.auth = function(e) {
    var popup = R.utils.openWindow(e.target.href, 520, 570, function(response) {
      R.utils.checkLoginStatus(this.success, {response: response}, response.value);

      // TODO Localize.
      if (response.value) {
        Swal.fire({
          html: "<img src='/assets/icons/outlook-progress.gif'>",
          showConfirmButton: false
        });
      } else {
        Swal.fire("Please allow popups and try again.");
      }
    }.bind(this));
  }
})();
