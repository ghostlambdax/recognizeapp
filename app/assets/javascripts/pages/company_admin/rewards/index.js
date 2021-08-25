window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_rewards-index"] = (function() {
  "use strict";
  var Rewards = function() {
    this.addEvents();
  };

  Rewards.prototype.addEvents = function() {
    var companyAdmin = new R.CompanyAdmin();

    $document.on(R.touchEvent, "#exportCSV-redeemed", function() {
      R.exportTableToCSV.apply(this, [$('#reward-redeemed-table'), 'recognize-rewards-redemptions.csv']);
    });

    $document.on(R.touchEvent, "#exportCSV-rewards", function() {
      R.exportTableToCSV.apply(this, [$('#rewards'), 'recognize-rewards-catalog.csv']);
    });
    $document.on("ajax:complete", "a.reward-status-toggle[data-remote]", rewardsStatusToggle);
  };
  return Rewards;
})();

function rewardsStatusToggle(e, response) {
  "use strict";
  if (response.status === 200) {
    var $this = $(e.target);
    $this.text($this.data('reward-status'));
  } else if (response.responseJSON && response.responseJSON.errors) {
    var title = response.responseJSON.errorTitle || 'An error occurred.';
    var errors = "<ul>" + response.responseJSON.errors.map(function(i){
      return '<li>' + i + '</li>';
    }).join("") + "</ul>";
    Swal.fire({icon: "error", title: title, html: errors});
  }
}