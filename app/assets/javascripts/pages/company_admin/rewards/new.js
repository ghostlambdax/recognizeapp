window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_rewards-new"] = window.R.pages["company_admin_rewards-edit"] = (function() {
  'use strict';


  function formatUser(user) {
    if (user.loading) {
      return "Please wait";
    }

    if (user.avatar_thumb_url === R.defaultAvatarPath) {
      user.avatar_thumb_url = "/assets/" + R.defaultAvatarPath;
    }

    var raw_template = $('#user_avatar_template').html();
    var template = Handlebars.compile(raw_template);
    return template({
      "avatar_url": user.avatar_thumb_url,
      "name": user.label
    });
  }

  function formatUserSelection(user) {
    return user.label || user.text;
  }

  function addRewardImage(e, data) {
    $document.find(".reward_image").attr("src", data.reward.image.url);
  }

  var Rewards = function() {
    this.variantListener = window.R.rewards.variantListener();
    this.addEvents();
  };

  Rewards.prototype.addEvents = function() {
    var companyAdmin = new R.CompanyAdmin();
    new window.R.Select2(this.bindRewardManagerAutocomplete);

    try {
      var $relevantContainer = $($document.find(".reward-card"));
      var uploader = new window.R.Uploader(
        $relevantContainer,
        addRewardImage,
        {
          submitBtn: $relevantContainer.find("input[type=submit]")
        }
      );
    } catch(e) {
      console.warn(e);
    }
  };

  Rewards.prototype.removeEvents = function() {
    $(".reward-manager-select").off();
    $document.off('click', 'form .new_reward, form.edit_reward');
    this.variantListener.off();
  };

  Rewards.prototype.bindRewardManagerAutocomplete = function() {
    var url = "/coworkers";
    var dept = window.R.utils.queryParams().dept;
    if(dept) {
      url += "?dept=" + dept;
    }
    $(".reward-manager-select").select2({
      ajax: {
        url: url,
        dataType: 'json',
        delay: 250,
        data: function(params) {
          return {
            term: params.term, // search term
            page: params.page,
            include_self: true
          };
        },
        processResults: function(data, page) {
          return {
            results: data
          };
        },
        cache: true
      },
      escapeMarkup: function(markup) {
        return markup;
      },
      minimumInputLength: 1,
      templateResult: formatUser,
      templateSelection: formatUserSelection
    });
  };

  return Rewards;
})();
