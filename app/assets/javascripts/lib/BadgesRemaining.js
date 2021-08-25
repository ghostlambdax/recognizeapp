window.R = window.R || {};
window.R.forms = window.R.forms || {};

window.R.BadgesRemaining = (function($, window, body, R, undefined) {
  'use strict';

  var BadgesRemaining = function($listWrapper) {
    this.$listWrapper = $listWrapper;
    this.renderBadgeLimits();
    this.addEvents();
  };

  function removedUser() {
    settingQuantityCount(1);
  }

  function removedTeam($el) {
    var count = parseInt($el.parent().data("count") || 0);
    settingQuantityCount(count);
  }

  function addedUser() {
    settingQuantityCount(-1);
  }

  function settingQuantityCount(num) {
    var $badgeQuantity = $(".image-wrapper .badge-quantity");
    var currentQuatity = $badgeQuantity.text();
    var newQuantity = parseInt(currentQuatity) + num;

    window.R.BadgesRemaining.setOriginalButtonInBadgeList(newQuantity);

    $badgeQuantity.text(newQuantity);

    if (newQuantity < 0) {
      $badgeQuantity.parent().addClass("warning");
    } else {
      $badgeQuantity.parent().removeClass("warning");
    }
  }

  function addedTeam(team) {
    settingQuantityCount(-(gon.team_counts[team.id]) || 0);
  }

  BadgesRemaining.prototype.addEvents = function() {
    $document.off("addedRecipient");
    $document.on("addedRecipient", function(event, recipient) {
      var type = recipient.type.toLowerCase();

      if (type === "team") {
        addedTeam(recipient);
      } else  {
        addedUser();
      }
    });

    $document.off("removedRecipient");
    $document.on("removedRecipient", function(event, isTeam, $el) {
      if (isTeam) {
        removedTeam($el);
      } else {
        removedUser();
      }
    });
  };

  BadgesRemaining.prototype.renderBadgeLimits = function(callback) {
    var endpoint = this.$listWrapper.data('badgesRemainingEndpoint');
    $.get(endpoint, function(data){
      this.badgeData = data.badges;
      this.addQuantities();
    }.bind(this));
  };

  BadgesRemaining.prototype.addQuantities = function() {
    var that = this;

    this.$listWrapper.find("li.badge-item").each(function(){
      var $badgeItem = $(this);
      var id = $badgeItem.data('badgeId');

      if(!id) {
        return;
      }

      var label = that.badgeData[id].quantity_with_interval_text;
      var quantity = that.badgeData[id].quantity;

      $badgeItem.attr('data-quantity', quantity);
      $badgeItem.find('.badges-remaining-wrapper').attr("data-badgeid", id).html(label);
    });

    $(".badge-loader").hide();
  };

  BadgesRemaining.setOriginalButtonInBadgeList = function(quantity) {
    var id = $(".image-wrapper .badges-remaining-wrapper").data("badgeid");
    var $button = $("#badge-item-"+id);

    quantity = quantity || $button.data("quantity");

    $button.find(".badge-quantity").text(quantity);
  };

  return BadgesRemaining;
  
})(jQuery, window, document.body, window.R);