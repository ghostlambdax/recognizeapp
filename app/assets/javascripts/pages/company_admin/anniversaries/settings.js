window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_anniversaries_settings-index"] = (function() {
  var FORM_ElEMENTS = ".edit_badge, .new_badge";
  var MAX_FILE_UPLOAD_SIZE_IN_MB = 5;

  var Anniversaries = function() {
    this.canHaveCurrencyValue = $("#anniversary-list .currency-value").length > 0;
    if (this.canHaveCurrencyValue) {
      this.generateCurrencyValues();
    }
    this.addEvents();
  };

  Anniversaries.prototype.generateCurrencyValues = function() {
    var $list = $("#anniversary-list > li");

    $list.each(function() {
      updatePrice($(this).find(".fields"));
    });
  };

  function updatePrice(el) {
    var $row = $(el),
        points = $row.find(".badge-input-points").val(),
        price = (points / gon.points_to_currency_ratio);

    $row.find(".currency-value").text(R.utils.formatCurrency(price));

  }

  Anniversaries.prototype.addEvents = function() {
    var companyAdmin;
    var $form = $(FORM_ElEMENTS);
    this.$inputs = $form.find("input:not(.on-off), textarea");
    
    // enable tab nav
    $(".anniversary-nav a").click(function (e) {
      e.preventDefault();
      $(this).tab('show');
    });

    // enable checkbox toggles
    $(".checkbox-wrapper input[type='checkbox']").iOSCheckbox({
      onChange: function() {
        var $this = $(this.elem);
        $this.parents('form').submit();
      }
    });

    if (this.canHaveCurrencyValue) {
      $document.on("keyup", '#anniversary-list .badge-input-points', function() {
        updatePrice($(this).closest(".fields"));
      });
    }

    // save text input data on change
    $document.on('change', ".badge-input-short_name, .badge-input-points, .badge-input-message", function(){
      var $this = $(this);
      $this.parents('form').submit();
    });

    // handle errors manually since form input id's wont match
    // what comes back from response
    $window.on("ajaxify:errors", function(evt, id, errors) {
      var formUuid = $("#"+id).data('formuuid');
      for (var key in errors) {
        var $errDiv = $("<div class='error'>");
        var errorMsgs = [];
        if (errors.hasOwnProperty(key)) {
          for(var i = 0; i < errors[key].length; i++) {
            var msg = errors[key][i];
            errorMsgs.push("<h5>"+msg+"</h5>");
          }
          $errDiv.html(errorMsgs.join("\n"));
          key = key.replace(/^badge_/, '');
          $("form[data-formuuid='"+formUuid+"'] [name='badge["+key+"]']").before($errDiv);
        }
      }
      this.enableInputs();
    }.bind(this));

    $form.on("ajax:beforeSend", function(e) {
      var $target = $(e.target);
      this.disableInputs($target.find("input:not(.on-off), textarea"));
    }.bind(this));

    $document.on("ajax:success", FORM_ElEMENTS, function(evt, data) {
      var formUuid = data.formuuid;
      $("form[data-formuuid='"+formUuid+"'] .error").remove();
      this.enableInputs();
    }.bind(this));

    this.setupBadgeImageUploader();
    companyAdmin = new R.CompanyAdmin();
  };

  Anniversaries.prototype.setupBadgeImageUploader = function() {
    // Hide badge image edit container at load
    $(".badge_image_edit_container .inner_container").hide();

    $document.on("change", "input[type=file]#badge_image", function(e){
      var options = { disableInput: false };
      if(this.files.length){
        var fileSize = this.files[0].size / (1024 * 1024);
        if(fileSize <= MAX_FILE_UPLOAD_SIZE_IN_MB){
          options.disableInput = true;
        }
      }
      that.changeStateOfInputs($(e.target), options);
    });

    var that = this;
    $document.on(R.touchEvent, ".change_badge_image", function(){
      var $relevantBtn = $($(this)[0]);
      var $relevantBadgeContainer = $relevantBtn.closest('.badge_image_edit_container');
      var $relevantBadgeForm = $relevantBadgeContainer.closest("form");

      changeStateOfBadgeImageEditContainer($relevantBadgeContainer);

      var uploaderCallback = function(e,json){
        that.setupBadgeAfterImageChange(json);
      };
      var uploaderOpts = {
        submitBtn: $relevantBadgeContainer.find(".change_badge_image"),
        fileUpload: {
          properties: {
            autoUpload: true,
            url: $relevantBadgeForm.attr("action"),
            formData: $relevantBadgeForm.serializeArray(),
            type: $relevantBadgeForm.attr("method")
          },
          // The presence of 'add' callback interferes with autoUpload functionality, therefore exclude it.
          excludedCallbacks: ["add"]
        }
      };

      // Bind jquery file uploader.
      new window.R.Uploader($relevantBadgeContainer, uploaderCallback, uploaderOpts);
    });
  };

  // When file is in the process of being uploaded, ensure all fields that when mutated would trigger AJAX request are
  // disabled. If they were not disabled, and an ajax request were to be fire, when the fileupload is in progress, the
  // submission would also try to include the file, causing redirection to root.
  Anniversaries.prototype.changeStateOfInputs = function($fileInput, options) {
    var isFileUploadInProgress = $fileInput.prop("files").length !== 0;
    var $relevantBadgeContainer = $fileInput.closest('.badge_image_edit_container');
    var $inputs = $relevantBadgeContainer.closest("form").find("input, textarea");
    if (isFileUploadInProgress && options.disableInput){
      this.disableInputs($inputs);
    } else {
      this.enableInputs($inputs);
    }
  };

  // To be called after badge edit image uploader returns with success.
  Anniversaries.prototype.setupBadgeAfterImageChange = function(json) {
    var $updatedBadge =  $("li#badge-" + json.badge.anniversary_template_id +" form");
    var $toBeUpdatedImgTag = $updatedBadge.find("img.anniversary-badge-image");
    $toBeUpdatedImgTag.attr('src', json.badge.permalink + '?' + new Date().getTime()).fadeIn(2000);
    $updatedBadge.find('.inner_container').hide();
  };

  function changeStateOfBadgeImageEditContainer(container) {
    var $relevantBadgeContainer = container;
    if ($relevantBadgeContainer.find('.inner_container').is(":visible") === false) {
      $relevantBadgeContainer.find('.inner_container').show();
    } else {
      $relevantBadgeContainer.find('.inner_container').hide();
      $relevantBadgeContainer.find('.error').remove();
    }
  }

  Anniversaries.prototype.enableInputs = function($inputs) {
    $inputs = $inputs || $(FORM_ElEMENTS).find("input:not(.on-off), textarea");
    $inputs.removeAttr("disabled");
  };

  Anniversaries.prototype.disableInputs = function($inputs) {
    $inputs.attr("disabled", "disabled");
  };

  Anniversaries.prototype.removeEvents = function() {
    R.utils.destroyIOSCheckboxes("#anniversary-list");
    $(".anniversary-nav a").off();
    $document.off('change', ".badge-input-short_name, .badge-input-points, .badge-input-message");

    // Events for badge image uploader -- BEGIN
    $document.off(R.touchEvent, ".change_badge_image");
    $document.off("change", "input[type=file]#badge_image");
    // Events for badge image uploader -- END
  };
  
  return Anniversaries;

})();
