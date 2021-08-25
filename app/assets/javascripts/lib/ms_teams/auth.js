window.R = window.R || {};
window.R.msTeams = window.R.msTeams || {};

window.R.msTeams.auth = (function($, window, body, R, undefined) {
  // if there is a currentUserId, it means we have a Recognize web session
  // and can skip Microsoft SSO Authentication
  // and just call callback
  var Auth = function(success, failure) {
    // if already logged in for some reason, just skip straight to callbacks
    if(R.msTeams.recognizeSession.loggedIn) {
      authSuccess();
      success();
    } else {
      // TODO: when SSO auth is ready for primetime
      //       Possibly add some condition to decide
      //       to do OAuth or SSO strategy
      registerOAuthHandlers(success, failure);
    }
  };

  function registerOAuthHandlers(success, failure) {
    $("#ms-teams-signin-btn").on('click', function(){
      doAuthViaOAuth(success, failure);
    });    
  }

  function doAuthViaOAuth(success, failure) { 
    var authPopupUrl = R.msTeams.recognizeSession.authPopupUrl;
    R.msTeams.client.authentication.authenticate({
        url: authPopupUrl,
        width: 600,
        height: 535,
        successCallback: function (result) {
          $(".ms-teams-unauthenticated-content").text("You've been successfully logged in. Redirecting you now...");
          success();
        },
        failureCallback: function (reason) {
          $(".ms-teams-unauthenticated-content .errors").text("Sorry. There was a problem signing you in. Please try again.");
        }
    });
  }
  // use for SSO Authentication
  // Not currently used while we wait for SSO Auth 
  // to reach general availability
  // https://github.com/ydogandjiev/taskmeow/issues/25
  function doAuthViaAuthToken(success, failure) {
    var authTokenRequest = {
        successCallback: function(token) { 
            var base64Url = token.split(".")[1];
            var base64 = base64Url.replace(/-/g, '+').replace(/_/g, "/");
            var parsedToken = JSON.parse(window.atob(base64));
            var nameParts = parsedToken.name.split(" ");
            var user = {
                family_name: nameParts.length > 1 ? nameParts[1] : "n/a",
                given_name: nameParts.length > 0 ? nameParts[0] : "n/a",
                upn: parsedToken.upn,
                name: parsedToken.name
            };
            window.R.msTeams.msUser = user;
            console.log("Success: "+token);
            authSuccess();
            success(user);
        },
        failureCallback: function(error) { 
          console.log("Failure: "+error);
          if(typeof(failure) !== "function") {
            //default failure is to replace unauthenticated content with error
            $(".ms-teams-unauthenticated-content").text("We're sorry. Authentication failed with error: "+error);
          } else {
            failure(error);            
          }
        }
    };

    window.R.msTeams.client.authentication.getAuthToken(authTokenRequest);    
  }  

  function authSuccess() {
    $(".ms-teams-unauthenticated-content").hide();
    $(".ms-teams-authenticated-content").hide().removeClass("hidden").fadeIn();    
  }
  return Auth;

})(jQuery, window, document.body, window.R);

