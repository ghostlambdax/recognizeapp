window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_redemptions-index"] = (function() {
  'use strict';

  var Redemptions = function() {
    this.addEvents();
  };

  Redemptions.prototype.verifyDenyPopup = function(el, title, description) {
    var $this = $(el);
    Swal.fire({
      title: title,
      text: description,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Confirm'
    }).then(function(result) {
      if (result.value) {
        this.removeSwalEvents();
        $this.click();
        this.addSwalEvents();
      }
    }.bind(this));
  };

  Redemptions.prototype.verifyApprovePopup = function(el, title, description) {
    var $this = $(el);

    var swalOpts = {
      icon: "warning",
      title: title,
      html: description,
      showCancelButton: true,
      confirmButtonText: "Confirm"
    };

    var isCompanyFulfilledReward = $this.data("rewardType") === "company_fulfilled_reward";

    if (isCompanyFulfilledReward) {
      var redemptionRewardAdditionalInstructions = $this.data("rewardAdditionalInstructions");
      swalOpts.input = "textarea";
      swalOpts.inputValue = redemptionRewardAdditionalInstructions || "";
      swalOpts.inputPlaceholder =  gon.redemption_additional_instructions_input_placeholder;
      swalOpts.inputAttributes =  {'name': 'additional_instructions'};
      if (redemptionRewardAdditionalInstructions) {
        swalOpts.html += "<p class='subtle-text smallPrint'><i>" + swalOpts.inputPlaceholder + "</i></p>";
      }
    }

    Swal.fire(swalOpts).
    then(function(result) {
      // Here, `result.value` -- when `confirm` button is pressed -- is set to additional instructions, which can be
      // empty. Therefore, rather than checking for `result.value` only, check whether or not the attribute is present.
      if (result.value !== undefined) {
        this.removeSwalEvents();
        var ajax_data = { _method: 'put', request_form_id: $this.data('request-form-id')};
        if (isCompanyFulfilledReward) {
          ajax_data.redemption_additional_instructions = result.value;
        }
        $.ajax({
          url: $this.data('endpoint'),
          type: 'post',
          data: ajax_data
        });
        this.addSwalEvents();
      }
    }.bind(this));
  };

  Redemptions.prototype.addEvents = function() {
    this.addSwalEvents();
    new R.CompanyAdmin();
    this.bindRedemptionViewLink();
    this.bindRedemptionAdditionalInstructionsLink();
  };

  Redemptions.prototype.addSwalEvents = function() {
    var $selector = $('body');
    $selector
      .on("ajaxify:error", ".approve-button",function(){
        $selector.on( R.touchEvent, ".approve-button", this.approveButton.bind(this));
      }.bind(this))
      .on(R.touchEvent, ".approve-button", this.approveButton.bind(this));
    $selector
      .on("ajaxify:error", ".deny-button",function(){
        $selector.on(R.touchEvent, ".deny-button", this.denyButton.bind(this));
      }.bind(this))
      .on(R.touchEvent, ".deny-button", this.denyButton.bind(this));
  };

  Redemptions.prototype.removeSwalEvents = function() {
    var $selector = $('body');
    $selector.off("ajaxify:error", ".approve-button");
    $selector.off("ajaxify:error", ".deny-button");
    $selector.off( R.touchEvent, ".deny-button");
    $selector.off( R.touchEvent, ".approve-button");
  };

  Redemptions.prototype.approveButton = function(e) {
    e.preventDefault();
    this.verifyApprovePopup(e.target, "Approve reward?", "Double checking you want to approve this reward.");
    return false;
  };

  Redemptions.prototype.denyButton = function(e) {
    e.preventDefault();
    this.verifyDenyPopup(e.target, "Deny reward?", "Double checking you want to deny this reward. It will automatically return the points.");
    return false;
  };

  Redemptions.prototype.removeEvents = function() {
  };

  Redemptions.prototype.bindRedemptionViewLink = function() {
    $document.on('click', '.redemption-view-link', function(){
      var $link = $(this);
      var redemptionData = $link.data('redemption');
      var redeemer = $link.data('redeemer');
      var date = new Date(redemptionData.createdAt);

      var redeemerString = "<div>"+redeemer + ' | ' + redemptionData.rewardName+"</div>";
      var createdAtString = "Order Reference ID: "+redemptionData.referenceOrderID+"<br><br><div>Delivered: "+date.toLocaleDateString() + ' ' + date.toLocaleTimeString()+"</div>";
      var claimString = "<div class='code'>Contact Recognize support if the reward email was not received by the recipient.</div>";
      var instructionsString = "<h5 class='marginTop10'>Redemption instructions: </h5><div class='redemptionInstructions'>"+redemptionData.reward.redemptionInstructions+"</div>";

      Swal.fire({
        title: redeemerString,
        html: createdAtString + claimString + instructionsString,
        customClass: 'redemptionSwal'
      });
    });
  };

  Redemptions.prototype.bindRedemptionAdditionalInstructionsLink = function() {
    $document.on('click', '.redemption-additional-instructions-link', function(){
      var redemptionAdditionalInstructionsTitle = gon.redemption_additional_instructions_title;

      var $link = $(this);
      var redemptionAdditionalInstructions = $link.data('redemption-additional-instructions');

      var redemptionAdditionalInstructionsHtml = "<div class='redemptionInstructions'>" + redemptionAdditionalInstructions + "</div>";

      Swal.fire({
        title: redemptionAdditionalInstructionsTitle ,
        html: redemptionAdditionalInstructionsHtml,
        customClass: 'redemptionSwal'
      });
    });
  };
  return Redemptions;
})();
