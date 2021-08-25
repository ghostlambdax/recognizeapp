
// Note: Recaptcha script is added multiple times on html head and is
// known issue registered on https://github.com/google/recaptcha/issues/236
// Because of this above issue user have to wait little longer on slow network.

window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.Captcha = (function($, window) {

  var C = function() {
    this.SRC = 'https://www.recaptcha.net/recaptcha/api.js';
    this.$targetForm = null;
    this.captchaBtnClass = '.captcha-trigger-button';
    this.addCallbacks();
    this.addEvents();
    // Events should be loaded before adding the script
    this.addExternalScript();
    this.numberOfTriesRemaining = 0;
  };

  C.prototype.addCallbacks = function() {
    this.registerSuccessCallback();
    this.registerErrorCallback();
  };

  C.prototype.registerSuccessCallback = function() {
    var that = this;
    // This callback is invoked by the recaptcha library after the client-side request was successful. It should be defined on `window`.
    window.captchaSuccessCallback = function(token) {
      that.$targetForm.find(".g-recaptcha-response").attr('value', token);
      that.$targetForm.trigger('submit');
    };
  };

  C.prototype.registerErrorCallback = function() {
    var that = this;
    // This callback is invoked by the recaptcha library when reCAPTCHA encounters an error (e.g. network connectivity)
    window.captchaErrorCallback = function() {
      if(that.numberOfTriesRemaining > 0){
        that.addCaptchaChallengeMutationHandler();
        try {
          grecaptcha.execute();
        } catch (e) {
          console.error(e);
        }
        that.numberOfTriesRemaining -= 1
      }
      else{
        var errorText = "Could not display recaptcha because of connection issue, please refresh the page and try again.";
        if(that.$targetForm.find('.error').text() != errorText) {
          // reCAPTCHA does not response errors on callback. More on https://developers.google.com/recaptcha/docs/invisible#js_param
          var errors = {"base": [errorText]};
          var formErrors = new window.R.forms.Errors(that.$targetForm, errors, {});
          formErrors.renderErrors();
        }
        window.recognize.patterns.formLoading.resetButton();
      }
    };
  };

  C.prototype.addEvents = function() {
    $(this.captchaBtnClass).on(R.touchEvent, this.attachCaptchaEvents.bind(this));
  };

  C.prototype.attachCaptchaEvents = function (e) {
    var $captchaTriggeredBtn = $(e.target);
    var $form = $captchaTriggeredBtn.closest('form');
    var allFieldsValid = $form.find('input').toArray().every(function (el) {
      // html5 input validation
      return el.checkValidity();
    });

    if (!allFieldsValid) {
      return
    }
    this.$targetForm = $form;
    window.recognize.patterns.formLoading.setupButtons($captchaTriggeredBtn[0]);
    this.addCaptchaChallengeMutationHandler();
    try {
      this.numberOfTriesRemaining = 3;
      grecaptcha.execute();
    } catch (e) {
      console.error(e);
    }
    e.preventDefault();    
  }
  // Handles the case where the Recaptcha challenge iframe is closed without verifying.
  // Code reference is taken from https://stackoverflow.com/a/44984658/6155553
  C.prototype.addCaptchaChallengeMutationHandler = function() {
    var callback = function(mutationList, observer) {
      for(var i = 0; i < mutationList.length; i++) {
        if(mutationList[i].target && mutationList[i].target.style.opacity === '0') {
          if(grecaptcha.getResponse().length === 0) {
            window.recognize.patterns.formLoading.resetButton();
          }
          observer.disconnect();
          break;
        }
      }
    };
    var observer = new MutationObserver(callback);

    var $recaptchaChallenge = $("iframe[title='recaptcha challenge']");
    $recaptchaChallenge.each(function(index, el){
      var $captchaDiv = $(el).parent().parent();
      observer.observe($captchaDiv[0], {attributes: true, attributeFilter: ['style']});
    });
  };

  // When using default loading technique `recaptcha/api.js` script will load multiple times and is unnecessary.
  // To prevent the multiple script loading issue, the script is loaded manually.
  C.prototype.addExternalScript = function() {
    var scriptSelector = "script[src='" + this.SRC + "']";
    if($(scriptSelector).length === 0) {
      var script = document.createElement('script');
      script.src = this.SRC;
      script.async = true;
      script.defer = true;
      $('body').append(script);
    }
  };

  return C;
})(jQuery, window);
