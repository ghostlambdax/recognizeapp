window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_top_employees-index"] = (function() {
  "use strict";
  var TopEmployees = function() {
    this.addEvents();
  };

  TopEmployees.prototype.addEvents = function() {
    var companyAdmin = new R.CompanyAdmin();
    this.pagelet = new window.R.Pagelet();

    this.dateRange = new window.R.DateRange({ container: $(".company_leaderboard") });

    $document.on(R.touchEvent, "#exportCSV-top-employees", function() {
      R.exportTableToCSV.apply(this, [$('#rank table'), 'recognize-top-employees.csv']);
    });


  };
  return TopEmployees;
})();

