window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_dashboards-show"] = (function() {
  'use strict';

  var Dashboard = function() {
    this.addEvents();
  };

  Dashboard.prototype.addEvents = function() {
    new R.CompanyAdmin();
    this.initGraphs();
    
  };

  Dashboard.prototype.removeEvents = function() {
  };

  Dashboard.prototype.initGraphs = function() {
    var colors = [];

    if (window.R.company && window.R.company.dashboard && window.R.company.dashboard.topBadges) {
      R.analytics.piechart({
        data: window.R.company.dashboard.topBadges
      });


    }

    if (window.R.company && window.R.company.dashboard && window.R.company.dashboard.usersByStatus) {
      R.analytics.piechart({
        container: 'piechart-user-by-status',
        data: window.R.company.dashboard.usersByStatus
      });
    }


    this.addResGauge("res-score");
    this.addResGauge("res-score-sender");

  };

  Dashboard.prototype.addResGauge = function(resId) {
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
  return Dashboard;

})();
