(function() {
    Recognize = Recognize || {};
    Recognize.pages = Recognize.pages || {};
    Recognize.pages["users-show"] = userProfile;
    var tabEl = "#column-two .column-two-left:nth-child(1) .yj-scrollbar-fix";


    // Constructor
    function userProfile() {
        var that = this;
        this.removeEvents();
        Recognize.file.load("/templates/users-show.html");
        this.yammerId = jQuery("[data-userid]").data("userid");
        that.createUserTab();
        this.createRecognitionLink();
        this.addEvents();
        jQuery(".header-actions").css("min-width", "389px");
    }

    userProfile.prototype.createUserTab = function() {
      var html;
      if (jQuery("#recognition-tab-trigger").length > 0) {
        return;
      }

      html = '<li id="recognition-tab-trigger" class="yj-filter-tab"><a href="" class="yj-filter-tab-link">'+Recognize.patterns.i18n().recognize+'</a></li>';

      this.$recognitionTabTrigger = jQuery( html );

      jQuery(".yj-action-bar-with-tabs .yj-tabs").append( this.$recognitionTabTrigger );

      this.createRecognitionTabContentWrapper();
    };

    userProfile.prototype.createRecognitionTabContentWrapper = function() {
      var $parent = jQuery("#column-two .column-two-left");

      this.$recognitionTab = jQuery("<div id='recognition-tab' class='yj-scrollbar-fix' style='display: none;'><div id='recognition-tab-content'><h2>"+Recognize.patterns.i18n().loading+"</h2></div></div>");

      this.$recognitionContent = this.$recognitionTab.find("#recognition-tab-content");

      $parent = $parent.length > 1 ? $parent.eq(1) : $parent.eq(0);

      if ($parent.length === 0) {
        $parent = jQuery("#column-two .yk-center-block > .yk-center-block");
      }

      $parent.append( this.$recognitionTab );
    };

    function getURL() {
        return  Recognize.patterns.api.endPoint+"/recognitions";
    }

    userProfile.prototype.showTab = function() {

        jQuery("#recognition-tab").siblings().hide();

        this.$recognitionTab.show();

        jQuery(".yj-tabs .yj-selected").removeClass("yj-selected");

        jQuery("#recognition-tab-trigger").addClass("yj-selected");
    };

    userProfile.prototype.hideTab = function() {
        this.$recognitionTab.siblings().show();
        this.$recognitionTab.hide();
        this.$recognitionTabTrigger.removeClass("yj-selected");
    };

    userProfile.prototype.triggerTab = function() {
        this.showTab();

        data = "yammer_id="+this.yammerId;

        var gettingRecognitions = Recognize.patterns.api.get("/recognitions", data);

        gettingRecognitions.done(this.loadRecognitions.bind(this));
        gettingRecognitions.fail(this.noRecognitions.bind(this));

    };

    userProfile.prototype.loadTabContent = function(html) {
      if (this.$recognitionContent.length === 0) {
        this.createRecognitionTabContentWrapper();
      }
      this.$recognitionContent.html(html);
    };

    userProfile.prototype.loadRecognitions = function(data) {
        var hbTemplate = Handlebars.compile( jQuery("#recognitions-template").html() );
        var html = hbTemplate(data.recognitions);
        this.loadTabContent(html);

    };

    userProfile.prototype.noRecognitions = function(data) {
        var error = JSON.parse(data.responseText);
        this.loadTabContent(error.message);
    };

    userProfile.prototype.addEvents = function() {
        var that = this;

        jQuery(document).on(R.touchEvent, "#recognition-tab-trigger", function(e) {
          e.preventDefault();
          that.triggerTab();
        });

        jQuery(document).on(R.touchEvent, ".yj-tabs li:not(#recognition-tab-trigger) a",  function() {
            jQuery(this).parent("li").addClass("yj-selected");
            that.hideTab();
        });

        $body.on(R.touchEvent, "#user-recognize-trigger", this.openRecognitionOverlay.bind(this));
    };

    userProfile.prototype.removeEvents = function() {
      jQuery(document).off(R.touchEvent, "#recognition-tab-trigger");
      jQuery(document).off(R.touchEvent, ".yj-tabs li:not(#recognition-tab-trigger) a");
      $body.off(R.touchEvent, "#user-recognize-trigger");
    };

    userProfile.prototype.openRecognitionOverlay = function(e) {
        Recognize.patterns.recognitionForm.open(this.yammerId);
    };

    userProfile.prototype.createRecognitionLink = function() {
      if (jQuery("#user-recognize-trigger").length > 0 || jQuery(".header-actions .yj-edit-profile").length > 0 || !this.yammerId) {
        return;
      }

      var $actionButtonList = jQuery(".yj-user-profile-header--actions");
      // The relevant button styles (eg. root-*) are dynamic, so copy them from corresponding buttons
      var buttonClasses = $actionButtonList.children('.y-layoutList--item').first().find('.ms-Button.y-button').attr("class") ||
                          'ms-Button y-button';

      var html =
        '<li class="y-layoutList--item">' +
          '<a id="user-recognize-trigger" class="' + buttonClasses + '" href="javascript://" role="button">' +
            '<div class="ms-Button-flexContainer">' +
              '<div class="y-block y-textSize-mediumSub">' +
                '<div class="y-block--inner y-textSize-mediumSub">' +
                  '<span class="y-button--icon-wrapper-left"> &#9733; </span>'+
                    Recognize.patterns.i18n().recognize +
                '</div>' +
              '</div>' +
            '</div>' +
          '</a>' +
        '</li>';

      $actionButtonList.prepend( html );
    };
})();
