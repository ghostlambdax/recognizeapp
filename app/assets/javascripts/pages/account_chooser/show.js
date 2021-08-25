window.R = window.R || {};
window.R.pages = window.R.pages || {};

(function () {
  window.R.pages["account_chooser-show"] = AccountChooser;
  var loggedinTimer;
  var email;

  function AccountChooser() {
    email = $("#account-chooser-wrapper").data("email");

    // This is for iFrame viewers
    $document.on(R.touchEvent, "#signUpNewCompany", function (e) {
      e.preventDefault();

      R.utils.openWindow($(this).attr("href"), 520, 570, function () {
        checkLoggedIn();
      });

      return false;
    });

    // If there is only one account then we show the please wait by default.
    if ($("#please-wait-wrapper").hasClass("current")) {
      setTimeout(function () {
        $(".account-chooser-button").click();
      }, 2000);
    } else {
      $(".account-chooser-button").bind("ajaxify:beforeSend", function (e, xhr) {
        R.transition.slide("#account-chooser-wrapper", "#please-wait-wrapper");
      });
    }
  }

  function checkLoggedIn() {
    clearTimeout(loggedinTimer);
    setTimeout(function () {
      $.get("/", function (d) {
        if (d.indexOf('home-index') === -1) {
          clearTimeout(loggedinTimer);
          window.location.href = '/';
        } else {
          checkLoggedIn();
        }
      });
    }, 2000);
  }

  AccountChooser.prototype.removeEvents = function () {
    $(".account-chooser-button").unbind("ajaxify:beforeSend");
  };
})();
