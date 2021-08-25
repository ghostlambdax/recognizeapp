(function() {
  var Page;
  window.R = window.R || {};
  window.R.pages = window.R.pages || {};

  Page = window.R.pages["users-edit"] = function() {
    // if (!$html.hasClass("ie9")) {
    //   $("form.edit_user").data("remote", true);
    // }
    if ($html.hasClass("ie9")) {
      $("form.edit_user").removeAttr("remote");
    }

    this.$progress = $('.progress-bar');

    this.addEvents();
  };

  Page.prototype.removeEvents = function() {
    $("#user_email_setting_attributes_global_unsubscribe").off("change");
    $("#user_avatar").off().unbind();
    $document.off(R.touchEvent, "#cancel-account input[type=submit]");
  };

  Page.prototype.updateAvatarAfterUpload = function(json) {
    var $toBeUpdatedImgTags = [$("#avatar-control img"), $("#header-profile-wrapper img.profile-pic")];
    $toBeUpdatedImgTags.forEach(function($imgTag){
      $imgTag.attr('src', json.avatar_image_url).fadeIn(2000);
    });
  };

  Page.prototype.bindAvatarUploader = function() {
    var that = this;
    var $avatarUploadContainer = $("#avatar-control");

    var uploaderCallback = function(e, json){ that.updateAvatarAfterUpload(json); };

    var uploaderOpts = {
      fileUpload: {
        properties: {
          autoUpload: true,
          url: $avatarUploadContainer.find("#user_avatar").data("url"),
          formData: {},
          type: 'patch'
        },
        // The presence of 'add' callback interferes with autoUpload functionality, therefore exclude it.
        excludedCallbacks: ["add"]
      }
    };

    new window.R.Uploader( $avatarUploadContainer, uploaderCallback, uploaderOpts);
  };

  Page.prototype.addEvents = function() {
    var that = this;
    this.bindTimezoneSelect2();
    this.bindAvatarUploader();
    $window.on("ajaxify:errors", function() {
      $body.animate({
        scrollTop: 0
      });
    });

    $("#user_email_setting_attributes_global_unsubscribe").on("change", function(){
      var $unsubscribe = $(this);
      if($unsubscribe.is(':checked')) {
        $(".email-settings div.controls:not(.unsubscribe-wrapper) input").addClass("disabled").prop("disabled", "disabled");
        $(".email-settings div.controls:not(.unsubscribe-wrapper) label").addClass("subtle-text");
      } else {
        $(".email-settings div.controls:not(.unsubscribe-wrapper) input").removeClass("disabled").removeAttr("disabled");
        $(".email-settings div.controls:not(.unsubscribe-wrapper) label").removeClass("subtle-text");
      }
    });

    $document.on(R.touchEvent, "#cancel-account input[type=submit]", function(){
      Swal.fire({
        title: "Are you sure?",
        text: "This will cancel your account and log you out.",
        icon: "warning",
        showCancelButton: true,
        customClass: "destroy-confirm-button",
        confirmButtonText: "Yes, cancel it!",
        closeOnConfirm: false
      }).then(function(result) {
        if (result.value) {
          $("#cancel-account").submit();
        }
      });
      return false;
    });
  };

  Page.prototype.bindTimezoneSelect2 = function() {
    new window.R.Select2(function(){
      $("#user_timezone").select2();
    });
  };


})();

