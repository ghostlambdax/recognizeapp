window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["companies-show"] = (function() {
  'use strict';

  var companyScope;

  var Company = function() {
    var newBadgeUploader, badgeImageEditUploader,  that = this;
    companyScope = $body.data('companyScope');

    // No more auto jump down
    if (location.hash) {
      setTimeout(function() {

        window.scrollTo(0, 0);
      }, 1);
    }

    this.addEvents();
    showCurrentTab();

    if ($("#company-admin-content-wrapper.paid").length === 0) {
      this.lockUnpaidCompanyAdmin();
      return;
    }

    var $relevantNewBadgeContainer = $("#new_badge");
    newBadgeUploader = new window.R.Uploader(
      $relevantNewBadgeContainer,
      function(e, json) {
        $relevantNewBadgeContainer[0].reset();
        var $newBadge = $(json.partial);
        $newBadge.hide().prependTo("#active-badges-wrapper").fadeIn("slow");
        $newBadge.find(".badge_image_edit_container .inner_container").hide();
        that.setupBadges($newBadge);
      },
      {
        submitBtn: $relevantNewBadgeContainer.find("input[type=submit]")
      }
    );

    // Hide badge image edit container at load
    $("#custom-badges .badge_image_edit_container .inner_container").hide();

    $document.on("click", "#custom-badges .widget-box .button.change_badge_image", function(){
      var $relevantBtn = $($(this)[0]);
      var $relevantBadgeContainer = $relevantBtn.closest('.badge_image_edit_container');

      // Bind jquery file uploader.
      badgeImageEditUploader = new window.R.Uploader(
        $relevantBadgeContainer,
        function(e,json){
          that.setupBadgeAfterImageChange(json);
        },
        {
          submitBtn: $relevantBadgeContainer.find(".change_badge_image"),
          fileUpload: {
            properties: {
              autoUpload: true,
              url: $relevantBadgeContainer.attr("data-endpoint"),
              formData: $relevantBadgeContainer.find("#badge_id").serializeArray(),
              type: 'patch'
            },
            // The presence of 'add' callback interferes with autoUpload functionality, therefore exclude it.
            excludedCallbacks: ["add"]
          }
        }
      );

      changeStateOfBadgeImageEditContainer($relevantBadgeContainer);
    });

    this.companyAdmin = new R.CompanyAdmin();
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

  Company.prototype.addResGauge = function(resId) {
    var $res = $("#"+resId);

    if ($res.children().length > 0) {
      $res.empty();
    }

    this.res = this.res || [];

    this.res.push(new JustGage({
      id: resId,
      value: $res.data('res'),
      min: 0,
      max: 100,
      symbol: "%",
      customSectors: [{
        color: "#FF0000",
        lo: 0,
        hi: 25
      }, {
        color: "#FFff00",
        lo: 25,
        hi: 50
      }, {
        color: "#06ff00",
        lo: 50,
        hi: 75
      }, {
        color: "#41a0d9",
        lo: 75,
        hi: 100
      }]
    }));
  };

  Company.prototype.removeEvents = function() {
    for(var i=0;i++;i<this.res.length) {
      delete this.res[i];
    }

    // Fix IOSCheckboxes checkboxes page restore issue
    R.utils.destroyIOSCheckboxes("#company-admin-content-wrapper");

    // Clear the tab's active class from previous navigation (if any) so that bootstrap's `shown` event is fired again
    // on page restore when 'show' ing the tab(). This is especially needed for settings & custom badges page
    $('.admin-nav > ul > li.active').removeClass('active');

    $("#custom-badges-disabled-link").unbind();
    $('a[data-toggle="tab"]').off('shown');

    if (this.$pointValues) {
      this.$pointValues.unbind("ajax:complete");
      this.$pointValues.unbind("ajax:complete");
    }

    $window.unbind("ajaxify:success:kioskUrlUpdated");
    $document.off("ajax:success", '.edit_reward');
    $(".badge-type-selectors input[type='radio']").off();
    $document.off('click', '.role_toggle');
    $document.off('click', '#all_teams_box');
    $document.off("click", "#custom-badges .widget-box .button.change_badge_image");
  };

  function showCurrentTab() {
    var url = document.location.toString();
    if (url.match('#')) {
      var tab = url.split('#')[1];
      if (tab === "view-drawer-wrapper") {
        tab = "custom_badges";
        if ($("#custom_badges .drawer-trigger").length) {
          $("#custom_badges .drawer-trigger").click();
        } else {
          $(function() {
            $("#custom_badges .drawer-trigger").click();
          });
        }

      }
      $('a[data-toggle="tab"][href="#' + tab + '"]').tab('show');
    }
  }

  function promptToPay(e) {
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

    Swal.fire({
        imageUrl: "/assets/badges/100/powerful.png",
        title: "Engage your staff",
        // text: "By upgrading to a paid package of Recognize, you can maximize its success through customizations and integration. Upgrade to start your movement. If you have any questions, <a href='/contact'>contact us</a>",
        text: 'Successful companies using Recognize customized their badges and more. Upgrade to start customizing.',
        showCancelButton: true,
        confirmButtonColor: "#5cc314",
        cancelButtonText: "I'll think about it",
        confirmButtonText: "Upgrade",
        animation: "slide-from-top"
    }).then(function(result) {
      if (result.value) {
        window.location = '/welcome/?upgrade=true';
      }
    });
  }

  Company.prototype.lockUnpaidCompanyAdmin = function() {
    this.$companyWrapper = $("#company-admin-content-wrapper");
    var $selects;

    $(".iOSCheckContainer").off('mousedown mousemove touchstart click');

    this.$companyWrapper.on('change mousedown touchstart click', '.iOSCheckContainer', function(e) {
      promptToPay(e);
      return false;
    });

    this.$companyWrapper.on('click', 'a:not(.unlocked):not(#upgrade-link),button,input[type=submit]:not(.unlocked)', function(e) {
      promptToPay(e);
      return false;
    });

    $("#company-admin-content-wrapper select").focus(function() {
      $(this).data('lastSelected', $(this).find('option:selected'));
    });

    $selects = $('#company-admin-content-wrapper select');
    $selects.change(function(e) {
      $(this).data('lastSelected').attr('selected', true);
      promptToPay(e);
      return false;
    });
  };

  Company.prototype.badgeNominationToggle = function() {
    var $this = $(this).find("input[type='checkbox']");
    var $sendingLimitSelect = $this.closest(".widget-box").find(".sending-limit-type-select");

    if ( $this.is(':checked') ) {
        $sendingLimitSelect.hide();
    } else {
        $sendingLimitSelect.show();
    }
  };

  Company.prototype.addEvents = function() {
    this.pagelet = new window.R.Pagelet();

    $document.on("keypress", ".requires-approval-wrapper .select2-search__field", function (e) {
      if (isNaN(e.key)) {
        return false;
      }
    });

    $document.on("click", "#custom-badges .nomination-wrapper .iOSCheckContainer", this.badgeNominationToggle);

    $("#custom-badges-disabled-link").bind(R.touchEvent, function(e) {
      var $destination = $($(this).attr("href"));
      e.preventDefault();

      $("html, body").animate({
        scrollTop: $destination.offset().top - 100
      });
    });

    $document.trigger("drawer-close", function() {
      if (window.location.hash) {
        window.location.hash = "#custom_badges";
      }
    });

    $('a[data-toggle="tab"]').on('shown', function(e) {
      var href = $(e.target).attr("href");
      var $imgs;

      if (href === "#dashboard") {
        R.ui.graph();

      } else if (href === "#custom_badges") {

        this.setupBadges($document);
        $imgs = $("#custom_badges .custom-badge-image");
        if ($imgs.first().attr("src") === "") {
          $imgs.each(function() {
            var $this = $(this);
            $this.attr("src", $this.data("img"));
            $this.attr("style", "");
          });
        }

      }

      if (window.history && window.history.pushState) {
        history.pushState(null, null, e.target.hash);
      }

      $('html,body').scrollTop(0);

      if ($('#company-admin-content-wrapper.unpaid').length > 0) {
        this.lockUnpaidCompanyAdmin();
      }
    }.bind(this));
  };

  // To be called after badge edit image uploader returns with success.
  Company.prototype.setupBadgeAfterImageChange = function(json) {
    var updatedBadgeId = json.badge_id;
    var $updatedBadge =  $("#custom-badges #badge-" + updatedBadgeId);
    var $toBeUpdatedImgTag = $updatedBadge.find("img");
    $toBeUpdatedImgTag.attr('src', json.badge_image_url + '?' + new Date().getTime()).fadeIn(2000);
    $updatedBadge.find('.inner_container').hide();
  };

  Company.prototype.setupBadges = function($parent) {
    var that = this;

    // $parent is to scope the events
    // on page load, parent is $document
    // however, when a page is created, $parent will be wrapper of new badge
    // so we can re-add the events safely without doubling up on existing badges
    var $achievementInputs = $parent.find(".achievement-wrapper *:not(.iOSCheckContainer) > .on-off");

    $achievementInputs.iOSCheckbox({
      onChange: function() {
        var $this = $(this.elem);
        var $parent = $this.closest(".badge-information-column");
        var $achievementOptions = $parent.find(".achievement-options");

        $parent.find(".badge-options:not(.static-option)").addClass("hidden");

        if ($this.prop('checked')) {
          $parent.find(".normal-options").addClass("hidden");
          $achievementOptions.removeClass("hidden");
        } else {
          $parent.find(".normal-options").removeClass("hidden");
          $achievementOptions.addClass("hidden");
        }
      }
    });

    var $nominationInputs = $(".nomination-wrapper *:not(.iOSCheckContainer) > .on-off");

    $nominationInputs.iOSCheckbox({
      onChange: function() {
        var $this = $(this.elem);
        var $parent = $this.closest(".badge-information-column");

        var $budgetInfoWell = $parent.find(".budget-info-well");
        var $nominationOptions = $parent.find(".nomination-options");
        var $pointsLabel = $parent.closest(".widget-box").find(".points-label");
        var $requiresApprovalWrapper = $parent.closest(".widget-box").find(".requires-approval-wrapper");

        if ($this.prop('checked')) {
          $budgetInfoWell.slideUp();
          $nominationOptions.slideDown();
          $pointsLabel.slideUp();
          $requiresApprovalWrapper.slideUp();
        } else {
          $budgetInfoWell.slideDown();
          that.updateBadgeBudget($this.parents(".badge"));
          $nominationOptions.slideUp();
          $requiresApprovalWrapper.slideDown();
          if ($parent.closest(".widget-box").find(".requires-approval").prop('checked')){
            $pointsLabel.slideUp();
          }else {
            $pointsLabel.slideDown();
          }
        }
      }
    });

    var $requiresApprovalCheckboxes = $(".requires-approval-wrapper .requires-approval:input[type=checkbox]");

    $requiresApprovalCheckboxes.on('click', function(){
      var $this = $(this);
      var $parent = $this.closest(".requires-approval-wrapper");
      if ($this.prop('checked')) {
        $parent.closest(".widget-box").find(".points-label").slideUp();
        $parent.find(".requires-approval-options").slideDown();
      } else {
        $parent.closest(".widget-box").find(".points-label").slideDown();
        $parent.find(".requires-approval-options").slideUp();
      }
    });

    this.bindPointValuesSelect2ForBadgesThatRequireApproval();
    this.bindApproverSelect2ForBadgesThatRequireApproval();


    new window.R.Select2(function() {
      $parent.find('.company-role-select').select2({
        tokenSeparators: [',', ' ']
      });
    });

    this.bindapprovalStrategyWrapper();
    this.bindBadgePointCalculators();
  };

  Company.prototype.bindapprovalStrategyWrapper = function() {
    $document.off('change', '.approver-select');
    $document.on('change', '.approver-select', function(){
      var selectedValueText = $(this).find("option:selected").text();
      var $approvalStrategyWrapper = $(this).parent().find(".approval-strategy-wrapper");
      var $approvalStrategyCheckbox = $approvalStrategyWrapper.find(".approval-strategy:input[type=checkbox]");

      var showApprovalStrategyWrapper = selectedValueText === "Manager";
      var resetApprovalStrategyCheckbox = !showApprovalStrategyWrapper ;

      showApprovalStrategyWrapper ?
          $approvalStrategyWrapper.removeClass('hidden') : $approvalStrategyWrapper.addClass('hidden')

      if(resetApprovalStrategyCheckbox) {
        $approvalStrategyCheckbox.prop('checked', false);
      }
    });
  };

  Company.prototype.bindPointValuesSelect2ForBadgesThatRequireApproval = function() {
    var $pointValuesSelect = $('.point-values-select');
    var pointValuesSelectPlaceholder = $pointValuesSelect.attr('placeholder');
    new window.R.Select2(function () {
      $pointValuesSelect.select2({
        tags: true,
        tokenSeparators: [',', ' '],
        placeholder: window.R.utils.isIE() !== false && window.R.utils.isIE() < 12 ? '' : pointValuesSelectPlaceholder
      });
    });
  };

  Company.prototype.bindApproverSelect2ForBadgesThatRequireApproval = function() {
    var $approverSelect = $('.approver-select');
    var approverSelectPlaceholder = $approverSelect.attr('placeholder');
    new window.R.Select2(function () {
      $approverSelect.select2({
        placeholder: window.R.utils.isIE() !== false && window.R.utils.isIE() < 12 ? '' : approverSelectPlaceholder
      });
    });
  };

  Company.prototype.bindBadgePointCalculators = function() {
    var that = this;

    var selector = '.badge-points, .sending-limit-wrapper input, .sending-limit-wrapper select, .requires-approval, .point-values-select';
    $document.on('keyup mouseup change', selector, function(){
      // console.log("calculator events triggered");
      that.updateBadgeBudget($(this).parents(".badge"));
    });
    $(selector).change();

    $(".company-role-select").on('change', function(evt){
      var $select = $(evt.target);
      var $badge = $select.parents(".badge");
      var roleIds = $select.val();
      var userCountHtml, $userCountWrapper;

      $.ajax({
        url: gon.counts_users_url,
        data: {role_ids: roleIds},
        dataType: 'json',
        success: function(data){
          var uniqueUserCount = roleIds ? data.unique_users_in_role : data.total;
          $badge.data('sendableusercount', uniqueUserCount);
          $userCountWrapper = $badge.find(".user-role-count-wrapper");

          if(roleIds) {
            $userCountWrapper.text(function(i,txt){ return txt.replace(/\d+/, uniqueUserCount)});
            userCountHtml = $userCountWrapper.html();

            if(uniqueUserCount === 1) {
              userCountHtml = userCountHtml.replace('people', 'person');
            } else {
              userCountHtml = userCountHtml.replace('person', 'people');
            }
            $userCountWrapper.html(userCountHtml);
            $userCountWrapper.show();
          } else {
            $userCountWrapper.hide();
          }

          that.updateBadgeBudget($badge);
        }
      });
    });
  };

  Company.prototype.updateBadgeBudget = function($badge) {
    var sendFrequency = parseInt($badge.find("input.sending-frequency").val());
    var badgePoints = getBadgePoints($badge);
    var $snippet = $badge.find(".point-money-snippet");
    var totalPointValue, totalMoneyValue;
    var badgeValue;


    if(gon.show_budgets && !badgeIsNomination($badge)) {
      var sendIntervalId = parseInt($badge.find("select.sending-interval-select").val());
      var conversionFactor = R.utils.interval_conversion_factor(gon.reset_interval_id, sendIntervalId);
      var userCount = $badge.data('sendableusercount');
      var perEmployeeValue;

      $badge.find(".employee-count").text(userCount);


      if (!sendFrequency) {
        sendFrequency = 0;
      }

      // sendInterval is a more frequent interval than reset interval
      // eg, weekly vs quarterly
      if(conversionFactor < 0) {
        totalPointValue = (sendFrequency * badgePoints * userCount) / Math.abs(conversionFactor);
      } else {
        totalPointValue = sendFrequency * badgePoints * userCount * conversionFactor;
      }

      perEmployeeValue = userCount ? (totalPointValue / userCount) : 0;

      // console.log("totalPointValue", totalPointValue);

      if (!isNaN(totalPointValue)) {
        totalMoneyValue = window.R.utils.formatCurrency(totalPointValue / gon.points_to_currency_ratio);
      }

      badgeValue = badgePoints === 0 ? window.R.utils.formatCurrency(0) : window.R.utils.formatCurrency(badgePoints / gon.points_to_currency_ratio);

      $badge.find(".point-to-currency").text(badgeValue);

      $snippet.data('pointValue', totalPointValue);
      $snippet.find(".point-snippet-value").html(totalPointValue.toLocaleString());
      $snippet.find(".money-snippet-value").html(totalMoneyValue);

      $badge.find(".point-snippet-per-employee-value").html(perEmployeeValue.toLocaleString());
      $badge.find(".money-snippet-per-employee-value").html(window.R.utils.formatCurrency(perEmployeeValue / gon.points_to_currency_ratio));

      $snippet.show();
    } else {
      $snippet.hide();
    }
    this.updateTotalBudget();
  };

  function getBadgePoints($badge) {
    var badgePoints;

    var approval = $badge.find(".requires-approval").is(":checked");

    if (approval) {
      badgePoints = Math.max.apply(null, $badge.find(".point-values-select").val())
    } else {
      badgePoints = parseInt($badge.find(".badge-points").val());
    }

    if (!badgePoints || badgePoints <= -Infinity || badgePoints >= Infinity) {
      badgePoints = 0;
    }

    return badgePoints;
  }


  // point-to-currency

  Company.prototype.updateTotalBudget = function() {
    var $badgeForm = $document.find("#custom-badges");
    var $budgetWrapper = $document.find("#budget-wrapper");
    var pointTotal = 0;

    $badgeForm.find(".badge.enabled .point-money-snippet").each(function(){
      var $el = $(this);
      var val = parseFloat($el.data('pointValue'));
      if(val) {
        pointTotal += val;        
      }
    });

    if(gon.show_budgets) {
      var totalMoneyValue = window.R.utils.formatCurrency(pointTotal / gon.points_to_currency_ratio);
      $("#point-budget-value").html(pointTotal.toLocaleString());
      $("#money-budget-value").html(totalMoneyValue);
      $budgetWrapper.show();
    } else {
      $budgetWrapper.hide();
    }

  };

  function successFeedback(message, element) {
    var $existingButtons = element.find(".success-mention");
    $existingButtons.remove();
    var $successButton = $('<p class="success-mention success-text">' + message + '</p>');
    element.append($successButton);
    $successButton.fadeOut(4000);
  }

  function pleaseWait($containerElement) {
    var $waitDiv = $("<div>Please wait...</div>");
    $waitDiv.css({ position: 'absolute', top: 200, left: 200 });
    $containerElement.append($waitDiv);
  }

  function badgeIsNomination($badge) {
    var nomCheckbox = $badge.find(".nomination-wrapper input[type='checkbox']");
    return nomCheckbox.is(':checked');
  }

  return Company;

})();
