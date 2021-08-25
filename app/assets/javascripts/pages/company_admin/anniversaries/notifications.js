window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_anniversaries_notifications-show"] = (function() {

  var AnniversaryNotifications = function() {
    this.addEvents();
  };

  AnniversaryNotifications.prototype.addEvents = function() {
    var companyAdmin;

    $document.on(R.touchEvent, '.role_toggle,.role_toggle_individual_team', function(e) {
      $(this).closest('form').submit();
    });

    companyAdmin = new R.CompanyAdmin();
  };

  AnniversaryNotifications.prototype.removeEvents = function() {
    $document.off(R.touchEvent, '.role_toggle,.role_toggle_individual_team');
  };
  
  return AnniversaryNotifications;

})();
