(function() {
  'use strict';

  var $document = window.$document || $(document);

  function FormLoading(ajaxSelectors, nonAjaxSelectors) {
    this.ajaxSelectors = ajaxSelectors;
    this.nonAjaxSelectors = nonAjaxSelectors;
    this.formLoadingText = "• • •";
    this.addEvents();
  }

  FormLoading.prototype.addEvents = function() {
    $document
      .on("ajax:beforeSend", this.ajaxSelectors, this.beforeSend.bind(this))
      .on("ajax:success", this.ajaxSelectors, this.success.bind(this))
      .on("ajax:error", this.ajaxSelectors, this.error.bind(this));

    $document.on("click", this.nonAjaxSelectors, this.setNonAjaxButton.bind(this));

    $document.on("click", "a.form-loading-button", function(e) {
      e.preventDefault();
      return false;
    });

    $(window).unload( this.resetButton.bind(this) );
    $document.on("turbolinks:before-cache", this.resetButton.bind(this));
  };

  FormLoading.prototype.setButtonText = function(text) {
    if (!this.button) {
      return;
    }

    if (!text) {
      text = this.button.text;
    } else {
      var disabledText =  this.button.$el.data('disable-with');
      // according to rails api disabled behaviour is added by default to the submit tags
      // http://api.rubyonrails.org/v5.0.6/classes/ActionView/Helpers/FormTagHelper.html#method-i-submit_tag
      // here we check if the disable-with is other than default ones
      // in such case we modify the disabled text
      if ( disabledText && disabledText === this.button.text ) {
        this.button.$el.data('disable-with', text);
      }
    }

    if (this.button.type.toLowerCase() === "button") {
      this.button.$el.text(text);
    } else {
      this.button.$el.val(text);
    }
  };

  FormLoading.prototype.beforeSend = function(e, xhr) {
    if ($(e.target).hasClass("form-loading-button")) {
      return xhr.abort();
    }

    this.showLoadingState(e);
  };

  FormLoading.prototype.success = function(e) {
    if (this.button && this.button.$el.data("lf-page-change") !== true) {
      this.resetButton();
    }
  };

  FormLoading.prototype.error = function(e) {
    this.resetButton();
  };

  FormLoading.prototype.resetButton = function() {
    if(!this.button) {
      return;
    }

    if (this.button.$el) {
      this.button.$el.removeClass("form-loading-button");
      this.button.$el.attr('disabled', false);
      // this.button.$el.closest("form").find(".button").removeClass("form-loading-button")
    }

    if (this.button.href) {
      this.button.$el.attr("href", this.button.href);
      this.button.$el.attr('disabled', false);
    }

    this.setButtonText();
    this.button = null;
  };

  FormLoading.prototype.setupButtons = function(targetElement) {
    var $button,
      $selector = $(targetElement),
      buttonType = targetElement.tagName.toUpperCase(),
      buttonConditional, href;

    if (buttonType !== "FORM") {
      $button = $selector;
    } else {
      $button = $selector.find("[type=submit]");
      if (!$button.length) {return;}
      buttonType = $button[0].tagName;
    }

    href = $button.attr("href");

    buttonConditional = ( ( buttonType.toLowerCase() === "button" || $button.hasClass("btn") || $button.hasClass("button") ) && buttonType.toLowerCase() !== "input" );
    var text = buttonConditional ? $button.text() : $button.val();
    if ($button.length) {
      $button.addClass("form-loading-button");
      // When recaptcha puzzle is visible the button has already been configured with `formloading` and if
      // verify button is clicked then it will trigger this function which has the button value of `• • •`. So without
      // this clause the captcha triggered button would have `• • •` even after completion of the request.
      if($.isEmptyObject(this.button) || text != this.formLoadingText) {
        this.button = {
          type: buttonConditional ? "button" : "input",
          $el: $button,
          text: text
        };
      }

      if (href && href.length > 0) {
        this.button.href = href;
        $button.attr("href", "javascript://");
      }

      this.setButtonText(this.formLoadingText);

    } else {
      this.button = null;
    }
  };

  FormLoading.prototype.showLoadingState = function(e) {
    var element = e.target || e;

    this.setupButtons(element);
  };

  FormLoading.prototype.setNonAjaxButton = function(e) {
    var $button = $(e.target);
    var $form = $button.closest("form");

    if ($button.closest("form[remote=true]").length > 0 ||
        $form.data("form-loading-indicator") === false ||
        $button.data("form-loading-indicator") === false ||
        isInvalidFormSubmission($form)
    ) {
      return;
    }

    this.setupButtons(e.target);

    setTimeout(function() {
      this.resetNonAjaxButton($button);
    }.bind(this), 120000);
  };

  FormLoading.prototype.resetNonAjaxButton = function($button) {
    this.resetButton();
  };

  function isInvalidFormSubmission($form) {
    return (
      $form.find('input:invalid').length > 0 ||       // html5 validation
      ($form.data('validator') && !$form.valid())     // jquery validation (check only if initialized)
    );
  }

  window.recognize = window.recognize || {};
  window.recognize.patterns = window.recognize.patterns || {};

  var ajaxSelectors = [
    "form[data-remote]:not('.form-loading-ignore')",
    "a[data-remote]:not('.form-loading-ignore')"
  ].join(',');
  var nonAjaxSelectors = [
    "form:not('[data-remote]'):not('.form-loading-ignore'):not('.intercom-composer') " +
      "[type='submit']:not('.form-loading-ignore')" ,
    "[data-show-processing]"
  ].join(',');

  window.recognize.patterns.formLoading = new FormLoading(ajaxSelectors, nonAjaxSelectors);

})();
