//

window.R = window.R || {};

window.R.Uploader = (function($, window, body, R, undefined) {
  'use strict';

  var N = function($container, callback, opts) {
    this.$container = $container;
    this.$submitBtn = $(opts.submitBtn);
    this.$fileInputField = opts.fileInputField ?  $(opts.fileInputField) : this.$container.find("input[type=file]");
    this.submitBtnText = this.$submitBtn.val();
    this.callback = callback;
    this.opts = opts;
    this.$progress = this.$container.find(".progress-bar");
    this.max_file_upload_size_in_mb = opts.max_file_upload_size_in_mb || 5;
    this.resetFileField();
    this.addEvents();
  };

  N.prototype.resetFileField = function() {
    // Remove previously cached file, if there are any. This solves the issue when, in a page revisit, if the file field
    // had previously cached a file, the submission would not go via Uploader but regular form submission, which
    // resulted in unintended redirects. For more, see https://github.com/Recognize/recognize/issues/1418.
    this.$fileInputField.val("");
  };

  N.prototype.addEvents = function() {
    var fileUploader = this.getGenericFileUploader();
    var customizedFileUploader = this.customizeFileUploader(fileUploader, this.opts);
    this.attachFileUploadHandler(customizedFileUploader);
  };

  N.prototype.getGenericFileUploader = function() {
    var that = this;
    // Generic File Upload object
    var fileuploadObject = {
      dataType: "json",
      maxNumberOfFiles: 1,
      autoUpload: false,
      maxFileSize: that.max_file_upload_size_in_mb * 1024 * 1024,
      messages: {
        maxFileSize: "File size should be less than " + that.max_file_upload_size_in_mb + " MB"
      },
      /* be wary of replaceFileInput - used to make sure selected file shows - may screw with iFrameTransport */
      /* https://github.com/blueimp/jQuery-File-Upload/wiki/Options#replacefileinput */
      replaceFileInput: false,
      add: function(e, formData) {
        that.$submitBtn.unbind();
        that.$submitBtn.on(R.touchEvent, function(evt){
          //this manual validation is only needed for cases when the file is uploaded via a submit button
          if($(evt.target).is("input[type='submit']")){
            var formElement = $(evt.target).closest('form');
            var inputElement = formElement.find("input[type='file']");
            // NOTE: this does not support multiple file upload input controls in a single form
            var inputFileSize = inputElement[0].files[0].size / (1024 * 1024); // size in megabytes
            if(inputFileSize > that.max_file_upload_size_in_mb){
              var error = "File size should be less than " + that.max_file_upload_size_in_mb +" MB";
              inputElement = "#" + inputElement.attr('id');
              var responseJSON = {};
              responseJSON[inputElement] = [error];
              var formErrors = new window.R.forms.Errors($(inputElement).closest('div'), responseJSON, error);
              formErrors.renderErrors();
              evt.preventDefault();
              evt.stopPropagation();
              return;
            }
          }
          evt.preventDefault();
          formData.submit();
        });
      },
      progressall: function (e, data) {
        var progress = parseInt(data.loaded / data.total * 100, 10);
        var $bar = that.$container.find(".progress-inner");

        $bar.css('width', progress + '%');

        if (progress === 100) {
          that.$container.find('.file-attach-progress .message').html("Uploading Complete. Processing file...");
          that.$progress.find("span").text("Uploaded");
          that.$progress.fadeOut(2000);
        }
      },
      beforeSend: function() {
        if (that.$submitBtn[0]) {
          window.recognize.patterns.formLoading.setupButtons(that.$submitBtn[0]);
        }
        that.$progress.find("span").text("Uploading");
        that.$progress.addClass("active");
        that.$progress.show();
      },
      fail: function(e, data) {
        that.failedUpload(data);
      },
      done: function(e, data) {
        var json = data.jqXHR.responseJSON;

        if(json && json.errors) {
          return that.failedUpload(data);
        }

        that.$progress.removeClass("active");

        that.$container.find(".error").remove();
        if ($(window).width() < 701) {
          R.ui.drawer.close();
        }

        if (that.callback) {
          that.callback(e, json);
        }
      },
      always: function(e, data) {
        that.$submitBtn.val(that.submitBtnText);
        that.$submitBtn.attr('disabled', null);

        that.$container.find('.file-attach-progress .message').html("");
        // Ensure the file is not cached. See #1418.
        that.$fileInputField.val("");
        that.$fileInputField.trigger("change");
        // Need to unbind the submit button to make sure that the files are not added from previous submit attempt
        that.$submitBtn.unbind();

        e.currentTarget = e.currentTarget || that.$container[0];
        R.ajaxify.success(e, data.response().result);
        window.recognize.patterns.formLoading.resetButton();
      }
    };
    return fileuploadObject;
  };

  N.prototype.customizeFileUploader = function(fileUploader, opts) {
    // Customization of File Upload object as per the opts
    if (opts && opts.fileUpload) {

      if (opts.fileUpload.properties) {
        var fileUploadProperties = opts.fileUpload.properties;
        for (var key in fileUploadProperties) {
          if (fileUploadProperties.hasOwnProperty(key)) {
            fileUploader[key]= fileUploadProperties[key];
          }
        }
      }

      if (opts.fileUpload.excludedCallbacks){
        var excludedCallbacks = opts.fileUpload.excludedCallbacks;
        for (var i = 0 ;  i < excludedCallbacks.length; i++) {
          if (fileUploader.hasOwnProperty(excludedCallbacks[i])) {
            delete fileUploader[excludedCallbacks[i]];
          }
        }
      }

    }

    return fileUploader;
  };

  N.prototype.attachFileUploadHandler = function(fileUploader) {
    this.fileupload = this.$container.fileupload(fileUploader)
    .on("fileuploadprocessfail", function(e, data){
      var error = data.files[data.index].error;
      var responseJSON = {'base': [error]};
      var formErrors = new window.R.forms.Errors($(this), responseJSON, error);
      formErrors.renderErrors();
    });
  };

  N.prototype.failedUpload = function(data) {
    var errors = data.jqXHR.responseJSON.errors;
    var formErrors = new window.R.forms.Errors(this.$container, errors, data.jqXHR.responseJSON);

    formErrors.renderErrors();
  };

  N.prototype.submit = function() {};

  N.prototype.reset = function() {};

  N.prototype.openCrop = function() {};

  N.prototype.closeCrop = function() {};

  return N;

})(jQuery, window, document.body, window.R);
