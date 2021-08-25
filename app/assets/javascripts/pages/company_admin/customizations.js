window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_customizations-show"] = (function() {
  'use strict';

  var Customizations = function() {
    this.addEvents();
    this.setLogo();
  };  

  Customizations.prototype.addEvents = function() {
    new R.CompanyAdmin();
    this.bindColorPickers();
    this.bindResetColorPickers();

    $("#company_customization_font_family").change(function() {
      document.querySelector("#email").style.fontFamily = $(this).val();
    });

    $window.on("ajaxify:success", this.setLogo);
  };

  Customizations.prototype.setLogo = function() {
    var url = $("#email-customizations-form .uploader-image-thumbnail").attr("src");
    $("#email-logo").attr("src", url);
  };

  Customizations.prototype.removeEvents = function() {
    $document.off('click', '#colorPickerReset');
  };

  Customizations.prototype.bindColorPickers = function() {
    $(".color-picker-form input").change(this.updateStyles);
    this.updateStyles();    
  };

  Customizations.prototype.bindResetColorPickers = function() {
    var $resetLink = $("#colorPickerReset");
    $document.on('click', "#colorPickerReset", function() {
      $.each($resetLink.data('defaults'), function(key, val) {
        $("#company_customization_"+key).val(val);
      });
      this.updateStyles();
    }.bind(this));
  };

  Customizations.prototype.updateStyles = function() {
    var $primaryBg = $("#company_customization_primary_bg_color");
    var $primaryText = $("#company_customization_primary_text_color");
    var $secondaryText = $("#company_customization_secondary_text_color");
    var $secondaryBg = $("#company_customization_secondary_bg_color");
    var $actionColor = $("#company_customization_action_color");
    var $actionColorText = $("#company_customization_action_text_color");

    var $header = $("#email-toolbar");
    var $headerP = $header.find("h3");
    var $bodyBg = $("#email-body");
    var $bodyP = $bodyBg.find("p");
    var $bodyA = $bodyBg.find(".button");

    $header.css("background", $primaryBg.val());
    $headerP.css("color", $primaryText.val());
    $bodyBg.css("background", $secondaryBg.val());
    $bodyP.css("color", $secondaryText.val());
    
    $bodyA.css({
      "background": $actionColor.val(),
      "color": $actionColorText.val()
    });

  };
  return Customizations;

})();
