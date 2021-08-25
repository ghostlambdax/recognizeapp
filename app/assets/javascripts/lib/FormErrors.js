window.R = window.R || {};
window.R.forms = window.R.forms || {};

window.R.forms.Errors = (function($, window, body, R, undefined) {
  'use strict';

 var FormErrors = function($form, errors, data) {
    this.$form = $form;
    this.errors = errors;
    this.data = data;
  };  

  FormErrors.prototype.setErrorText = function(errorText, element) {
    var $el;
    var $errorElement = $('<div class="error not-visible"></div>');
    $errorElement.html("<h5>"+errorText+"</h5>");

    if(element === "base") {
      var $base = $("#base_errors");
      if($base.length === 0) {
        this.$form.prepend($errorElement.css("text-align", "center"));
      } else {
        $("#base_errors").before($errorElement.css("text-align", "center"));
      }
    } else {
      $el = $(element);

      if ($el.length === 0) {
        // First look inside this.$form
        $el = this.$form.find("#"+element);
        // Then, look outside this.$form (in the whole DOM), if needed.
        if ($el.length === 0) {
          $el = $("#"+element);
        }
      }

      if(this.data && this.data.formuuid) {
        $("form[data-formuuid="+this.data.formuuid+"]").find($el).before($errorElement);
      } else {
        if($el.length === 0) {
          element +=("_"+this.data.id);
          $el = $("#"+element);
        }
        $el.before($errorElement);
      } 

    }
    setTimeout(function() {$errorElement.removeClass("not-visible");}, 50);
  };


  /*
   Returns an array of consolidated error messages from errors object.

   This is handy when manual handling of errors is necessary when input ids in current view don't match what comes
   back in server response.
   Example:
    this.errors = { "attribute_x": ["Attribute x error"], "attribute_y": ["Attribute y error 1", "Attribute y error 2"] }
    getErrorMessages() // Expected output: ["Attribute x error", "Attribute y error 1", "Attribute y error 2"]
  */
  FormErrors.prototype.getErrorMessagesFromErrorsObject = function() {
    var errorMessages = [];
    var normalizedErrors = this.resolveErrorsThatStartWithCaret(this.errors);
    for (var key in normalizedErrors) {
      if (normalizedErrors.hasOwnProperty(key)) {
        var messages = normalizedErrors[key]; // messages is an array of error messages
        messages.forEach(function(message){
          errorMessages.push(message);
        });
      }
    }
    return errorMessages;
  };

  /*
  There are certain error messages that begin with a caret (^) symbol. (See en.yml for some examples). These error
   message signify that they are used standalone without the relevant attribute prepended to the message.
    For eg:
      self.errors.add(:file, "must be present") outputs the error message as "File must be present"
                VS
      self.errors.add(:file, "^The extension is invalid") outputs the error message as "The extension is invalid"

   This logic is handled in JsonResouce#json_for_errors. However, this logic only gets executed for responses triggered
   by `respond_with` method. Reponses that instead directly render json (Eg: `render json: { errors: @obj.errors })`
   aren't intercepted by JsonResource ; this causes the error messages to have caret(^) symbol prepended at the
   beginning of the error message.

   This method attempts to solves this.
  */
  FormErrors.prototype.resolveErrorsThatStartWithCaret = function(errors) {
    for (var key in errors) {
      if (errors.hasOwnProperty(key)) {
        var messages = errors[key]; // messages is an array of error messages
        messages = messages.map(function(message){
          var messageStartsWithCaret = message.indexOf("^") === 0;
          if (messageStartsWithCaret) {
            return message.replace(/^\^/, '');
          }
          return message;
        });
        errors[key] = messages;
      }
    }
    return errors;
  };

  FormErrors.prototype.renderErrors = function() {

    this.clearErrors();
    this.errors = this.resolveErrorsThatStartWithCaret(this.errors);
    
    for (var element in this.errors) {      
      var el = document.getElementById(element);
      var targetEl = (el && el.dataset && el.dataset.errorelement) ? el.dataset.errorelement : element;

      if (this.errors.hasOwnProperty(element)) {
        
        if (this.errors[element].constructor === Array) {          
          this.errors[element].forEach(function(error) {
            this.setErrorText(error, targetEl);
          }.bind(this));
        } else {
          this.setErrorText(this.errors[element], targetEl);
        }
        
      }
    }
  };

  FormErrors.prototype.clearErrors = function() {
    this.$form.find(".error").remove();
    $('.form-errors').remove();
  };

  return FormErrors;
  
})(jQuery, window, document.body, window.R);