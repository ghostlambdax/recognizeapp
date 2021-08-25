window.R = window.R || {};
window.R.pages = window.R.pages || {};


window.R.pages["home-office365"] = (function($, window, undefined) {
  'use strict';

  var loadOutlookTimer = 0;

  function loadOutlookSDK(callback) {
    if (window.Office) {
      clearTimeout(loadOutlookTimer);
      callback();
    } else {
      loadOutlookTimer = setTimeout(function() {
        loadOutlookSDK(callback);
      }, 100);
    }
  }

  function getCurrentUserEmail(){
    return Office.context.mailbox.userProfile.emailAddress;
  }

  function loginUserByEmail(email) {
    var idp = new window.R.IdpRedirecter();
    idp.checkIdp(email, "/redirect/recognitions/new_panel"+window.location.search);
  }

  var O = function() {
    var integrations;
    loadOutlookSDK(function() {
      window.Office.initialize = function(){
        loginUserByEmail(getCurrentUserEmail());
      };
    });

    integrations = new window.R.Integrations(this.success);

  };

  O.prototype = {
    success: function() {
      var $loading, outlookUrl;

      Swal.close();

      $loading =  $("#loading");
      $loading.removeClass("displayNone");

      $(".masterhead .sign-up, footer").addClass("displayNone");
      $(".offerings, #navbar").fadeOut(2000);

      setTimeout(function() {
        $loading.find(".text").text("Signing in");

        setTimeout(function() {
          $loading.find(".text").html("Still signing in<br>Please be patient");
        }, 7000);
      }, 5000);

      if (window.location.href.indexOf("viewer=outlook") > -1) {
        outlookUrl = "/redirect/recognitions/new_panel?viewer=outlook";
        if (window.R.utils.queryParams().referrer) {
          outlookUrl += "&referrer="+window.R.utils.queryParams().referrer;
        }

        window.location = outlookUrl;
      } else {
        window.location = "https://"+window.location.host + window.location.search;
      }
    }
  };
  
  return O;
})(jQuery, window);