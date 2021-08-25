window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["redemptions-index"] = (function() {
  'use strict';
  var RedemptionsIndex = function() {
    var layoutMode = "fitRows";
    this.$container = $("#rewards-cards");
    this.addEvents();
    this.updateAllRewardCardAsPerSelectedVariantQuantity();

    this.$container.isotope({
      itemSelector : '.reward-card',
      layoutMode: layoutMode,
      getSortData : {
        points : function ( $elem ) {
          return JSON.parse($elem.attr("data-points"));
        }
      },
      sortBy : 'points',
      sortAscending: true
    });
  };

  RedemptionsIndex.prototype.addEvents = function() {
    this.bindConfirmRedemption();
    this.bindRewardVariantSelection();

    $("#filter-redeemable").bind(R.touchEvent, function() {
      this.$container.isotope({ filter: '.redeemable' });
    }.bind(this));

    $("#filter-all").bind(R.touchEvent, function() {
      this.$container.isotope({ filter: '.reward-card' });
    }.bind(this));

    $("#sort-ascending").bind(R.touchEvent, function() {
      this.$container.isotope({ sortBy : 'points', sortAscending: true });
    }.bind(this));

    $("#sort-descending").bind(R.touchEvent, function() {
      this.$container.isotope({ sortBy : 'points', sortAscending: false });
    }.bind(this));

    $window.bind("ajaxify:success:updatedRewards", function(evt, response) {
      this.rewardRedeemed(evt, response);
    }.bind(this));
  };

  RedemptionsIndex.prototype.updateAllRewardCardAsPerSelectedVariantQuantity = function() {
    var that = this;
    $(".reward-card").each(function() {
      var $rewardCard = $(this);
      that.updateRewardCardAsPerSelectedVariantQuantity($rewardCard);
    });
  };

  RedemptionsIndex.prototype.bindRewardVariantSelection = function() {
    var that = this;
    $("select.redemption-variant-select").change(function() {
      var $rewardCard= $(this).closest(".reward-card");
      that.updateRewardCardAsPerSelectedVariantQuantity($rewardCard);
    });
  };

  RedemptionsIndex.prototype.updateRewardCardAsPerSelectedVariantQuantity = function($rewardCard) {
    var rewardHasVariantsWithQuantity = $rewardCard.hasClass('has-variants-with-quantity') === true;
    var rewardHasVariantsSelect = $rewardCard.find("select.redemption-variant-select").length !== 0;
    // Caution: A reward with one variant with quantity doesn't have `select`.
    if(rewardHasVariantsWithQuantity && rewardHasVariantsSelect) {
      var $selectedVariant = $rewardCard.find("select.redemption-variant-select").find("option:selected");
      this.updateAvailabilityStatusInRewardCard($rewardCard, $selectedVariant);
    }
  };

  RedemptionsIndex.prototype.updateAvailabilityStatusInRewardCard = function ($rewardCard, $selectedVariant) {
    var selectedVariantAvailabilityStatus = $selectedVariant.data("variant-availability-status");
    var selectedVariantIsRedeemable = selectedVariantAvailabilityStatus === "redeemable";
    if (selectedVariantIsRedeemable) {
      $rewardCard.find('button').prop('disabled', false).removeClass('disabled');
      $rewardCard.removeClass("unredeemable").addClass("redeemable");
    } else {
      $rewardCard.find('button').prop('disabled', true).addClass('disabled');
      $rewardCard.removeClass("redeemable").addClass(selectedVariantAvailabilityStatus).addClass("unredeemable");
    }
  };

  function formattedTerms(label, terms){
    var message = '<div class="alignLeft tango-terms">' + "<h4>"+ label +"</h4>" + terms + '</div>';
    message = message + "<hr>";
    return message;
  }

  function formattedLabel(label){
    var message = "<p><i>" + label + "</i></p>";
    return message;
  }

  RedemptionsIndex.prototype.bindConfirmRedemption = function() {
    $document.on(R.touchEvent, "#redemptions-index .confirmForm button", function(e) {
        var $this = $(this);
        var rewardCard = $(this).closest('.reward-card');
        var rewardImg = rewardCard.data('image');
        var rewardTerms = rewardCard.data('reward-terms');
        var rewardsTermsLabel = rewardCard.data('rewards-terms-label');

        var rewardLabel = rewardCard.find("select").children("option:selected").data("label") ||
                            rewardCard.find("input#redemption_variant_id").data("label");
        var rewardTitle = rewardLabel + " " + rewardCard.data('title');

        // to show the reward-variant label below the reward title in confirmation pop-up
        // var swal_message = formattedLabel(rewardLabel);
        var swal_message = "";
        if(rewardTerms !== ""){ // this is present for cash-equivalents rewards only
          swal_message += formattedTerms(rewardsTermsLabel, rewardTerms);
        }

        e.preventDefault();

        Swal.fire({
            title: rewardTitle,
            imageUrl: rewardImg,
            html: swal_message,
            showCancelButton: true,
            confirmButtonText: '✓ ' + gon.redeem,
            cancelButtonText: '✖ ' + gon.cancel
        }).then(function(result){
        if (result.value) {
          $this.closest("form").submit();
        }
      });

      return false;
    });
  };

  RedemptionsIndex.prototype.rewardRedeemed = function(evt, response) {
    var $form = $("form[data-formuuid='"+response.data.formuuid+"']");
    var $wrapper = $form.parents(".reward-card");
    var quantity = 0;

    Swal.fire({
      title: response.data.params.content.title,
      html: response.data.params.content.description,
      imageUrl: response.data.params.redemption.image_url,
      icon: 'success',
      showCancelButton: false,
      confirmButtonText: 'Got it'
    });

    $wrapper.removeClass("redeemable").addClass("redeemed");

    $wrapper.find(".reward-form-wrapper").hide();

    quantity = response.data.params.remaining_quantity <= 0 ? 0 : response.data.params.remaining_quantity;
    $wrapper.find(".reward-quantity").text(quantity);

    $wrapper.addClass("redeemed-success");

    var userRedeemablePoints = response.data.params.redeemable_points;
    this.updatePointsAvailableToRedeem(userRedeemablePoints);
    this.updateAvailabilityOfRewards(userRedeemablePoints);
  };

  RedemptionsIndex.prototype.updatePointsAvailableToRedeem = function(userRedeemablePoints) {
      $("span.redeemable_points_total").html(userRedeemablePoints);
  };

  RedemptionsIndex.prototype.updateAvailabilityOfRewards = function(userRedeemablePoints) {
    var that = this;
    $(".reward-card").each(function(){
      var $this = $(this);

      var pointsNeeded = -(userRedeemablePoints - parseInt($this.data('points')));

      if(pointsNeeded > 0) {
        $this.removeClass("redeemable").addClass("unredeemable");
        $this.find(".points-needed").html(pointsNeeded);
      } else {
        $this.removeClass("unredeemable").addClass("redeemable");
      }

      that.updateAvailabilityOfRewardVariant($this, userRedeemablePoints);
    });
  };

  //Remove variants unreedemable by points.
  RedemptionsIndex.prototype.updateAvailabilityOfRewardVariant = function($rewardCard, userRedeemablePoints) {
    var $variantSelectOptions = $rewardCard.find("select.redemption-variant-select option");
    $variantSelectOptions.each(function(){
      var $option = $(this);
      var variantPoint = $option.data('points');
      var pointsNeeded = -(userRedeemablePoints - parseInt(variantPoint));
      if (pointsNeeded > 0) {
        $option.remove();
        var variantSelectOptionsNoMore= $rewardCard.find("select.redemption-variant-select option").length === 0;
        if (variantSelectOptionsNoMore) {
          $rewardCard.removeClass('has-variants-with-quantity');
        }
      }
    });
  };

  RedemptionsIndex.prototype.removeEvents = function() {
    $document.off(R.touchEvent, "#redemptions-index .confirmForm button");
    $window.unbind("ajaxify:success:updatedRewards");
  };

  return RedemptionsIndex;

})();
