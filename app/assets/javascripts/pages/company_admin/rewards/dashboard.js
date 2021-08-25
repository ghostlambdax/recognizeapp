window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_rewards-dashboard"] = (function() {
  var Rewards = function() {
    this.addEvents();
  };

  Rewards.prototype.addEvents = function() {
    new R.CompanyAdmin();
    this.initPieCharts();
  };

  Rewards.prototype.initPieCharts = function() {
    if (window.R.company && window.R.company.dashboard && window.R.company.dashboard.pieChartDataGiftCards) {
      R.analytics.piechart({
        data: window.R.company.dashboard.pieChartDataCompany,
        container: 'top-company-rewards-piechart',
        lang: {
          noData: "No company fulfilled rewards have been approved yet."
        }

      });

      if(window.R.company.dashboard.pieChartDataGiftCards[0].data.length > 0
         && $('#top-giftcard-rewards-piechart').length) {
        R.analytics.piechart({
          data: window.R.company.dashboard.pieChartDataGiftCards,
          container: 'top-giftcard-rewards-piechart',
          lang: {
            noData: "No gift cards have been approved yet."
          }
        });

      }
    }
  };

  Rewards.prototype.removeEvents = function() {};

  return Rewards;
})();
