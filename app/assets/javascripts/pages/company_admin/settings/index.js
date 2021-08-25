window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_settings-index"] = (function($, window, undefined) {

  var companyScope;

  function Settings() {
    this.pagelet = new window.R.Pagelet();
    companyScope = $body.data('companyScope');
    this.turnOnSelectInputs();
    this.addEvents();
    this.turnOnToggles();
    new window.R.ScrollMenu("#company-admin-settings-menu", ".scroll-item", '.content-wrapper');
    new window.R.SwalForm();

  }

  function updateCurrencySymbol() {
    var currencySymbol = $("select#currency option:selected").data("currency-symbol");
    $("#currency-prefix").html(currencySymbol);
  }


  function updateRequireRecognitionTagsToggleDisplay(data){
    if (data.show_recognition_tags){
      $("#require-recognition-tags").show();
    }
    else{
      $("#require-recognition-tags").hide();
    }
  }

  function getURL(path) {
    return '/' + companyScope + path;
  }

  Settings.prototype.turnOnToggles = function() {
    var $inputs = $(".on-off:not(.remoteCheckboxToggle)"), that = this;

    $inputs.iOSCheckbox({
      onChange: function() {
        var $target = $(this.elem), data = {};
        var checkedValue = !!this.elem.prop("checked");
        if ($target.data('invert-values') === true) { // used as `invert_values` in view
          checkedValue = !checkedValue;
        }
        data[$target.data('setting')] = checkedValue;
        that.updateSettings(data);
      }
    });

  };

  Settings.prototype.turnOnSelectInputs = function() {
    var $input = $("select.old-autosave"), that = this;
    that.selectInputs = that.selectInputs || {};

    $input.focus(function() {
      var $target = $(this);

      that.selectInputs[$target.uniqueId()] = $target.val();
    });

    $input.change(function() {
      var $target = $(this), data = {};
      var value = $target.val();
      data[$target.data('setting')] = value;

      //////////////////////////////////////////////////
      //
      // FIXME: the condition to update the select setting
      //        in on all selects right now...
      //        However, there is only one select input, so this is ok
      //        for now....
      //        if another is added, we'll need to figure out a way to
      //        generalize the condition
      //
      //////////////////////////////////////////////////
      if( $target.prop('id') !== 'reset-interval' ) {
        that.updateSettings(data);
      } else {
        var msg = "Changing the reset interval will reset all the point totals relative to the selected interval. This may take a few minutes to process.  Are you sure?";
        Swal.fire({
          title: 'Are you sure?',
          text: msg,
          icon: 'warning',
          showCancelButton: true
        }).then(function(result){
          if (result.value){
            Swal.fire(
              'Successfully updated.',
              'Please allow a few minutes for changes to go through the system.',
              'success'
            );
            that.updateSettings(data);
          } else {
            $target.val(that.selectInputs[$target.uniqueId()]);
          }
        });
      }
    });
  };

  Settings.prototype.updateSettings = function(data) {
    var isResetInterval = "reset_interval" in data;
    var isChangeCurrency = "currency" in data;
    var isShowRecognitionTags = "show_recognition_tags" in data;
    $.ajax({
      url: getURL('/company/update_settings'),
      type: "POST",
      data: { settings: data },
      success: function() {
        if (isResetInterval) {
          updateUI();
        }
        else if (isChangeCurrency) {
          updateCurrencySymbol();
        }
        else if(isShowRecognitionTags) {
          updateRequireRecognitionTagsToggleDisplay(data)
        }
      }
    });
  };

  function updateUI() {
    var headerTarget = "#header #header-profile-wrapper";
    $.get(window.location + " "+headerTarget, function(data) {
      $(headerTarget).replaceWith($(data).find(headerTarget));
    });
  }

  Settings.prototype.addEvents = function() {
    this.companyAdmin = new R.CompanyAdmin();
    this.bindSyncGroupsSelect();
    this.bindSyncProviderSelect();
    this.bindDefaultYammerGroupIdToPostSelect2();
    this.bindDefaultYammerGroupIdToPostContainerToggle();
    this.bindSyncEnabledToggle();
    this.bindSamlSsoToggle();

    // Disabled until workplace gives us a way to post automatically.
    //
    // this.bindFacebookWorkplaceForm();
    // new window.R.Select2(function(){this.getFbWorkplaceGroups(true);}.bind(this));

    this.bindAutoSaveSettings();
    this.bindProfileBadgeSelect2();
    this.bindCurrencySelect2();
    this.bindTimezoneSelect2();
    this.bindConfirmationSwalForGiftCardRedemptionAutoApproval();
    this.bindCancelAccount();
    this.bindWebhookEvents();

    this.$pointValues = $("#point-values");
    this.$pointValues.bind("ajax:complete", updateUI);

    $window.bind("ajaxify:success:kioskUrlUpdated", function(evt, data) {
      var $kioskURL = $("#kiosk-url");
      $kioskURL.html(data.data.params.kiosk_url_partial);
      $kioskURL.closest("form").find(".error").remove();
    });

    this.$pointValues.bind("ajax:complete", function() {
      return successFeedback("Values Updated", this.$pointValues);
    }.bind(this));
  };

  Settings.prototype.bindConfirmationSwalForGiftCardRedemptionAutoApproval = function(){
    var $container = $("#require_approval_for_provider_reward_redemptions");
    var $checkbox = $container.find(".checkbox-wrapper .on-off");
    var $clickInterceptorOverlay = $container.find(".click_interceptor_overlay");

    // Set the overlay's width to match the siblings width to avoid accidental clicks.
    $clickInterceptorOverlay.width($container.find("label.checkbox-title").width());

    $clickInterceptorOverlay.on(R.touchEvent, function() {

      var checkboxIsChecked = $checkbox.attr("checked") ? true : false;
      var userIntendstoUncheckTheCheckbox = checkboxIsChecked;

      // Only show confirmation swal, when the user is about to turn the relevant setting `off`.
      if (userIntendstoUncheckTheCheckbox) {
        Swal.fire({
          title: "Are you sure?",
          html: $checkbox.data("swal-description"),
          icon: 'warning',
          showCancelButton: true,
          confirmButtonText: 'Okay'
        }).then(function(result){
          if(result.value){
            $container.find(".iOSCheckContainer").click();
          }else {
            // No-op
          }
        });
      } else { // User intends to check the checkbox.
        $container.find(".iOSCheckContainer").click();
      }
    });
  };

  Settings.prototype.bindCancelAccount = function(){
    var $container = $("#cancel-account input[type=submit]");
    $container.on(R.touchEvent, function(){
      Swal.fire({
        title: "Are you sure?",
        text: "This will cancel your account and log you out.",
        icon: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
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

  Settings.prototype.bindWebhookEvents = function() {

    // Webhooks table is pagelet
    // So, turn on remoteCheckboxToggles
    $("#webhooks .pagelet").on('pageletLoaded', function () {
      window.R.ui.remoteCheckboxToggle();
    }.bind(this));

    function getSelectedValFromEventList() {
      return $(".swal2-content .recent_events").val();
    }

    function doTestWebhookAction(evt) {
      var $target = $(evt.target);
      var objectGid = getSelectedValFromEventList();
      var url = $target.data('endpoint');
      var $webhookForm = $target.parents('.swal2-content form');
      var urlWithObjectId = R.utils.addParamsToUrlString(url, { object_gid: objectGid})
      // $(".swal2-content .output").html(urlWithObjectId); // for testing
      $(".swal2-content .output").css({opacity: 0.5})
      $.post({
        url: urlWithObjectId,
        data: $webhookForm.serialize()
      }).then(function(){
        $(".swal2-content .output").css({ opacity: 1 })
      })
      evt.preventDefault();
      return false
    }

    // see test payload
    $document.on(R.touchEvent, ".seePayloadLink", doTestWebhookAction);

    // send test event
    $document.on(R.touchEvent, ".testWebhookLink", doTestWebhookAction);
  }

  Settings.prototype.removeEvents = function() {
    // Needed here because settings are saved instantly on change so the updated select values should be shown on restore
    R.utils.saveSelectValuesToDom('#company_admin_settings-index .content-wrapper');

    // This allows the pagelet (& thus the sync groups select2) to initialize again on page restore
    $(".company_setting_sync_groups_container").removeClass('pagelet-loaded');
    $document.off("change", "select#company_post_to_yammer_group_id");
    $document.off("click", "#allow-posting-to-yammer-wall.checkbox-wrapper");
    $(".on-off").unbind();

    window.R.utils.destroyIOSCheckboxes('#company_admin_settings-index .content-wrapper');
  };

  Settings.prototype.bindAutoSaveSettings = function() {
    this.companyAdmin.autosaveSetting(".autosave-setting-form input, .autosave-setting-form select, .autosave-setting-form textarea");
  };

  Settings.prototype.bindProfileBadgeSelect2 = function() {
    new window.R.Select2(function(){
      $("#company_setting_profile_badge_ids").select2();
    });
  };

  Settings.prototype.bindTimezoneSelect2 = function() {
    new window.R.Select2(function(){
      $("#company_setting_timezone").select2();
    });
  };

  Settings.prototype.bindCurrencySelect2 = function() {
    new window.R.Select2(function(){
      $("#currency").select2();
    });
  };

  Settings.prototype.getFbWorkplaceGroups = function(firstLoad){
    var that = this;
    var $select = $("#company_setting_fb_workplace_post_to_group_id");
    this.selectedFbWorkplaceGroupId = $select.data('selectedgroupid');

    $.get($select.data('groupsendpoint'), function(data){
      $select.html($('<option />')); // need this for placeholder

      //normalize and sort if an array
      if(data.length) {
        data = $.map(data, function (obj) {
          obj.text = obj.name; // normalize name attribute to select2's required text
          return obj;
        });

        data = data.sort(function(a, b) {
          var nameA = a.text.toUpperCase(); // ignore upper and lowercase
          var nameB = b.text.toUpperCase(); // ignore upper and lowercase
          if (nameA < nameB) {
            return -1;
          }
          if (nameA > nameB) {
            return 1;
          }
          return 0;
        });
      }

      $select.select2({
        placeholder: 'Please select a group',
        allowClear: true,
        data: data,
      });

      // .select2('val', that.selectedFbWorkplaceGroupId);
      $select.val(that.selectedFbWorkplaceGroupId).trigger('change.select2');

      if(!firstLoad) {
        $select.select2('open');
      }

    });
  };

  Settings.prototype.bindFacebookWorkplaceForm = function(){
    var that = this;
    var done = function(){
      that.getFbWorkplaceGroups();
    };

    this.companyAdmin.autosaveSetting('#company_setting_fb_workplace_community_id', done);
    this.companyAdmin.autosaveSetting('#company_setting_fb_workplace_token', done);
    this.companyAdmin.autosaveSetting('#company_setting_fb_workplace_post_to_group_id', null, null, null, function(){
      console.log(that.selectedFbWorkplaceGroupId);
    });
  };

  Settings.prototype.bindSamlSsoToggle = function() {
    $document.on('keyup', '#saml_configuration_metadata_url', function(){
      var $el = $(this);
      var disabled;

      if($el.val() === '') {
        disabled = false;
      } else {
        disabled = true;
      }
      $("#saml-custom-fieldset input, #saml-custom-fieldset textarea").prop('disabled', disabled);
      console.log($el.val());
    });
    var event = jQuery.Event('keyup');
    event.target = $document.find('#saml_configuration_metadata_url')[0];
    $document.trigger(event);
  };

  Settings.prototype.bindSyncEnabledToggle = function() {
    $("#allow-sync-enabled").on('click', function() {
    });
  };

  Settings.prototype.bindSyncProviderSelect = function() {
    $("#company_sync_provider").change(function(){
      var $this = $(this);
      $this.parent('form').submit();
      var provider = $this.val();
      $(".sync-provider-wrapper").addClass('displayNone');
      $("#sync_provider_"+provider).removeClass('displayNone');
    });
  };

  Settings.prototype.bindDefaultYammerGroupIdToPostContainerToggle = function() {
    var $allowPostingToYammerWallCheckboxWrapper = $("#allow-posting-to-yammer-wall.checkbox-wrapper");
    var $allowPostingToYammerWallCheckbox = $allowPostingToYammerWallCheckboxWrapper.find(".on-off:input[type=checkbox]");
    var $companyPostToYammerGroupIdWrapper = $(".company_post_to_yammer_group_id_wrapper");

    if($allowPostingToYammerWallCheckbox.prop("checked") === true){
      R.YammerGroupsSelect2.initialize();
    }

    $allowPostingToYammerWallCheckboxWrapper.on('click', function(){
      if($allowPostingToYammerWallCheckbox.prop("checked") === true){
        $companyPostToYammerGroupIdWrapper.show();
        R.YammerGroupsSelect2.initialize();
      } else{
        $companyPostToYammerGroupIdWrapper.hide();
      }
    });
  };

  Settings.prototype.bindDefaultYammerGroupIdToPostSelect2 = function() {
    var $groupSelect = $('select#company_post_to_yammer_group_id');

    $groupSelect.on("select2:select", function(){
      var network = $body.data("name");
      var endpoint= "/" + network + "/company/update_settings";

      var $select = $(this);
      var selectedGroupId = $select.val();
      var payload = { };
      payload[$select.attr("name")] = selectedGroupId;

      $.ajax({
        url: endpoint,
        data: payload,
        method: "POST"
      });
    });
  };

  Settings.prototype.bindSyncGroupsSelect = function() {
    $(".company_setting_sync_groups_container").bind('pageletLoaded', function(evt) {

      var $target = $(evt.target);

      new window.R.Select2(function() {
        var $selectWidget = $target.find('select.company-setting-sync-groups');

        var config = {}; // default
        var url = $selectWidget.data('url');
        var lazyLoad = $selectWidget.data('lazyload');

        // Sync Providers specify if their groups need to be Lazy loaded
        // Microsoft Graph only for the time being
        if (lazyLoad) {
          var remoteConfig = getConfigForRemoteSelect2(url, $selectWidget);
          $.extend(config, remoteConfig);
        }

        $selectWidget.select2(config);

        $selectWidget.bind('select2:select', '.company-setting-sync-groups', function(event) {
          var groupId = event.params.data.id;
          $.ajax({
            url: url,
            data: { group_id: groupId },
            method: "post"
          });
        }.bind(this));

        $selectWidget.bind('select2:unselect', '.company-setting-sync-groups', function(event) {
          var groupId = event.params.data.id;
          var parts = url.split("?");
          var baseUrl = parts[0];
          var queryParams = window.R.utils.paramStringToObject(parts[1]);

          $.ajax({
            url: baseUrl + "/" + groupId + "?" + $.param(queryParams),
            data: { _method: "delete" },
            type: 'post'
          });
        });
      });

      function getConfigForRemoteSelect2(url, $select) {
        var remoteParamsKey = 'remoteParams'; // for data attribute
        return {
          minimumInputLength: 1,
          ajax: {
            url: url,
            dataType: 'json',
            delay: 250, // wait before triggering the request on keypress
            data: function (params) { // ajax params
              return {
                term: params.term.trim(), // user search term,
                remote_params: $select.data(remoteParamsKey)
              };
            },
            processResults: function (data) { // transform ajax response into Select2 format
              var formattedData = data.values
                .map(function (group){
                  return {
                    id: group.id,
                    text: group.displayName
                  };
                });
              return {
                results: formattedData,
                pagination: {
                  more: !!data.has_more
                }
              };
            },
            success: function (response) {
              if (response.has_more){
                // store remote params (eg. skip_token) to be used in next pagination request
                $select.data(remoteParamsKey, response.remote_params);
              }
            },
            error: function (xhr) {
              if (xhr.statusText === 'abort') { return }

              var errorMessage = (xhr.responseJSON && xhr.responseJSON.error) ||
                'There was a problem loading groups. Please try again later.';
              var $loadingIndicator = $(".select2-results__option.loading-results");
              $loadingIndicator.text(errorMessage);
            }
          },
          templateResult: formatGroupResult
        };
      }

      // for consistent loading message
      function formatGroupResult(group) {
        if (group.loading) {
          return "Please wait";
        }

        return group.text;
      }

    });
  };


  return Settings;
})(jQuery, window);
