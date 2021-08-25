(function() {
  var $badgeList;
  window.R = window.R || {};
  window.R.ui = window.R.ui || {};
  window.R.ui.BadgeList = BadgeList;

  var $badgeEdit;

  BadgeList.prototype = {
      addEvents: function() {
          var that = this;
          this.$badgeTrigger = $("#top .image-wrapper");
          this.$badgeTrigger = this.$badgeTrigger.length > 0 ? this.$badgeTrigger : $("form .image-wrapper");
          $badgeList = $('#badge-list');

          var isNotEditForm = !$("form").hasClass('edit_recognition');
          if (isNotEditForm) {
            this.$badgeTrigger.bind("click", function (e) {
              e.preventDefault();

              R.transition.fadeTop("#recognize-badge-list-wrapper");

              $("#best-wrapper").show();

            }.bind(this));
          }

          $document.on("click", ".badge-item .button", function() {
              $(this).closest(".badge-item").click();
          });

          $document.on("click", ".badge-item", function(e) {
              var $this = $(this);
              var $badge = $this.find(".badge-image-small");
              var badge = {
                  id: $badge.data("badge-id"),
                  name: $badge.data("name"),
                  relativeImagePath: $badge.data("relativeimagepath")
              };
              $("#recognition_badge_id").val(badge.id);
              $("#nomination_badge_id").val(badge.id);
              $(".image-wrapper").addClass("chosen");

              that.chooseBadge($this);

              if (that.type === 'recognition') {
                that.handleForcedPrivacy($this);
              }
          });

          $document.on("click", "#badge-list .badge-image-small", function(e) {
              $(this).siblings(".button").trigger(R.touchEvent);
          });
      },

      removeEvents: function() {
          if (this.$badgeTrigger) { this.$badgeTrigger.unbind("click"); }
          $document.off('click', '.badge-item');
          $document.off('click', '.badge-item .button');
          $document.off('click', '#badge-list .badge-image-small');
      },

      closeOverlays: function() {
          R.transition.fadeTop();
      },

      chooseBadge: function($badgeButton) {
          if ( $badgeButton.attr("id") === "upgrade-badges-link-badge" ) {
              return Turbolinks.visit($badgeButton.prop('href'));
          }

          var $badge = $badgeButton.find(".badge-image-small");
          var id = $badge.data("badge-id");
          var badge = {
              name: $badge.data("name"),
              className: $badge.data("cssclass"),
              relativeImagePath: $badge.data("relativeimagepath")
          };

          R.BadgesRemaining.setOriginalButtonInBadgeList();

          setBadgeLimit($badgeButton);

          var largeBadgeWrapper = this.$badgeTrigger.find("#badge-trigger")[0];

          $("#"+this.type+"_badge_id").val(id);
          $(".subtle-text").removeClass("edit");

          $badgeEdit = get$badgeEdit();
          $badgeEdit.removeClass("hidden");

          this.$badgeTrigger.addClass("edited");

          // largeBadgeWrapper.className = "badge-image "+badge.className;
          largeBadgeWrapper.className = "";

          var $badgeImage = $("<img>");
          $badgeImage.attr('src',  badge.relativeImagePath);
          $(largeBadgeWrapper).html( $badgeImage );

          if ($html.hasClass("ie8")) {
              largeBadgeWrapper.className = largeBadgeWrapper.className.replace("badge-image", "badge-image-small");
          }

          $("#badge-name").text(badge.name).removeClass("subtle-text");

          if ($window.width() <= 690) {
              $("body, html").scrollTop(0);
          }
          this.closeOverlays();
      },

      handleForcedPrivacy: function ($badgeItem) {
        this.$privacyInput = this.$privacyInput || $('input[name="recognition[is_private]"]');
        if (!this.$privacyInput.length) { return }

        this.privacyEnforcer = this.privacyEnforcer || new RecognitionPrivacyEnforcer(this.$privacyInput);
        var privacyEnforced = this.privacyEnforcer.isActive();
        var newBadgeForcesPrivacy = ($badgeItem.data('force-private') === true);

        if (newBadgeForcesPrivacy && !privacyEnforced) {
          this.privacyEnforcer.activate();
        } else if (!newBadgeForcesPrivacy && privacyEnforced) {
          this.privacyEnforcer.deactivate();
        }
      }
  };


  function setBadgeLimit($badgeButton) {
    var recipientUserCount = recipientCount();
    $badgeEdit = get$badgeEdit();

    $badgeButton.find(".badge-quantity").text(parseInt($badgeButton.data("quantity")) - recipientUserCount);

    var $limitHtml = $badgeButton.find(".badges-remaining-wrapper").clone();
    var $badgeQuantity = $(".image-wrapper .badge-quantity");
    var numLeft;

    if ($limitHtml.children().length > 0) {
      $badgeQuantity.parent().remove();
      numLeft = parseInt($badgeButton.data("quantity")) - recipientUserCount;

      if (numLeft < 0) {
        $limitHtml.addClass("warning");
      } else {
        $limitHtml.removeClass("warning");
      }

      $limitHtml.find(".badge-quantity").text(numLeft);

      $badgeEdit.after($limitHtml);
    } else {
      $(".image-wrapper .badges-remaining-wrapper").remove();
    }
  }


  function BadgeList(type) {
    this.type = type || "recognition";
    this.addEvents();
  }

  function recipientCount() {
    var userCount = $("#chosen-recepient-wrapper .recipient-wrapper:not(.team)").length;
    var teamCount = 0;

    $("#chosen-recepient-wrapper .recipient-wrapper.team").each(function() {
      teamCount += $(this).data("count") || 0;
    });

    return userCount + teamCount;
  }

  function get$badgeEdit() {
    return $("#badge-edit");
  }


})();
