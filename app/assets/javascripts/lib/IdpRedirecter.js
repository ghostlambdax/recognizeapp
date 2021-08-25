window.R = window.R || {};

window.R.IdpRedirecter = (function($, window, body, R, undefined) {
  'use strict';

  var IdpRedirecter = function() {};

  IdpRedirecter.prototype.hideLoginFields = function(selectors) {
    selectors.forEach(function (selector) {
      var $login = $(selector);
      $login.find('.password-control-group').hide();
      $login.find('.submit-control-group').hide();
      var $lookupBtnWrapper = $login.find('.lookup-control-group');
      $lookupBtnWrapper.removeClass('hidden');

      // using sample element to fetch the parent form
      // the lookup-form class is used later to listen on the inner email field
      var $form = $lookupBtnWrapper.closest('form');
      $form.addClass('lookup-form');
    });
  };

  /**
   * Note: we no longer need to manually exclude the idp page here because
   *     the click / keypress events that invoke this method are only bound on the custom lookup classes
   *     that were explicitly added in this file initially in hideLoginFields() - which excludes the idp page
   */
  IdpRedirecter.prototype.advanceLogin = function(target) {
    var that = this;
    // target can be input or button
    var $form = $(target).closest('form');
    var $field = $form.find('.user-session-email:visible');
    var email = $field.val();

    // HTML5 validation does not work here because the submit button is actually a link
    if (!email.trim()) {
      var errors = {"base": ["Login cannot be empty"]};
      var formErrors = new window.R.forms.Errors($form, errors, {});
      formErrors.renderErrors();
      return;
    }

    var redirectPath = window.R.utils.queryParams().redirect;

    $field.addClass('loading');

    /**
     *  Note: The done() and fail() callbacks below apply to the (manual) _login forms only
     *        as they are handled by IdpRedirecter by default
     *        It does not cover other custom (integration) login flows that manually use IdpRedirecter.checkIdp()
     */
    this
      .checkIdp(email, redirectPath)
      .done(function(data){
        var idpUrl = data.idp_url;
        if (idpUrl) {
          $(".user-session-password").prop('disabled', true);
        } else {
          $field.removeClass('loading');
          that.renderAccountNotFoundError($form);
        }
      }).fail(function (xhr) {
        // handle throttled request manually, as this is manual ajax request
        // and thus not covered by Ajaxify
        if (xhr.status === 429) {
          R.utils.setThrottledErrorIfNeeded(xhr);

          var errors = xhr.responseJSON.errors;
          var formErrors = new window.R.forms.Errors($form, errors, {});
          $field.removeClass('loading');
          $form.parent().find('.message-info').remove(); // clear flash
          formErrors.renderErrors();
        }
      });
  };

  // show inline error instead of redirecting to login page that shows same form with the error
  // this code was originally located in app/views/ms_teams/signup.html.erb
  IdpRedirecter.prototype.renderAccountNotFoundError = function($form){
    $form.parent().find('.message-info').remove(); // clear flash
    // TODO (maybe): localize error message
    var errors = {"base": ["Account could not be found"]};
    var formErrors = new window.R.forms.Errors($form, errors, {});
    formErrors.renderErrors();
    window.recognize.patterns.formLoading.resetButton();
  };

  IdpRedirecter.prototype.addEventsForAuthFields = function() {
    var t = this;
    var hiddenFields = [
      '#login-menu',            // Main (top) Navigation
      '#user_sessions-new',     // /login
      '#signups-recognize',     // /signup/recognize
      '#signups-fb_workplace',  // /signup/fb_workplace
      // pw input is already hidden for ms teams, but still needs to be listed here to switch the submit button
      '#ms_teams-signup'        // /ms_teams/signup
    ];

    this.hideLoginFields(hiddenFields);

    $document.on('click', '.lookup-control-group .lookup-button', function(event) {
      t.advanceLogin(event.target);
    });

    $document.on('keydown', '.lookup-form .user-session-email', function(event) {
      if ( event.keyCode === 13 ){ // return key
        event.preventDefault();
        t.advanceLogin(event.target);
      }
    });
  };

  IdpRedirecter.prototype.removeEvents = function() {
    $document.off('click', '.lookup-control-group .lookup-button');
    $document.off('keydown', '.user-session-email');
  };

  IdpRedirecter.prototype.checkIdp = function(email, redirectPath, opts) {
    var dataOpts = {
      email: email,
      redirect: redirectPath,
      current_href: window.location.href
    };

    var queryParams = R.utils.queryParams();
    if (queryParams.viewer) {
      dataOpts.viewer = queryParams.viewer;
    }

    if (opts && opts.outlook_identity_token) {
      dataOpts.outlook_identity_token = opts.outlook_identity_token;
    }

    if (opts && opts.fb_workplace_params) {
      dataOpts.fb_workplace_params = opts.fb_workplace_params;
    }

    if (opts && opts.ms_teams_params) {
      dataOpts.ms_teams_params = opts.ms_teams_params;
    }

    if (opts && opts.referrer) {
      dataOpts.referrer = opts.referrer;
    }

    if (opts && opts.viewer) {
      dataOpts.viewer = opts.viewer;
    }

    console.log("idp", dataOpts);
    // must return a promise, so that it can be chained
    return $.ajax({
      url: "/idp_check",
      data: dataOpts
    }).done(function(data){
      var idpUrl = data.idp_url;
      if (idpUrl) {
          // multiple accounts, one may be sso, one may not be
          // if one sso account is found, idpUrl should be /saml/sso
          // and not /account_chooser
          // If no accounts are sso, let user choose account and then go to idp page
          // which if oauth is chosen should pop open window

        window.location = idpUrl;
      } else if (data.message) {
        // no-op, handled separately by clients for which this data is relevant (eg. workplace)
      } else {
        // The logic here is that if there is a current user
        // then follow the redirect. If there is no current user
        // don't follow (EG. Do nothing) - The use case of this
        // is in the header on the home page. A user enters no email
        // or a fragment or email that doesn't exist. Leave them there
        // correct their typing or do a different action altogether
        if (redirectPath && window.R.utils.isLoggedInLayout()) {
          if(window.history.pushState) {
            Turbolinks.visit(redirectPath);
          } else {
            window.location = redirectPath;
          }
        }
      }
    });
  };
  return IdpRedirecter;
})(jQuery, window, document.body, window.R);
