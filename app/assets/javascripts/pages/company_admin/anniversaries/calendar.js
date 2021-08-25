window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_anniversaries_calendars-show"] = (function() {

  var AnniversaryCalendar = function() {
    this.addEvents();
  };

  AnniversaryCalendar.prototype.addEvents = function() {
    var companyAdmin;

    companyAdmin = new R.CompanyAdmin();
    new window.R.Select2(function(){
      $(".select2").select2();
    });
  };

  AnniversaryCalendar.prototype.removeEvents = function() {
  };
  
  return AnniversaryCalendar;

})();
