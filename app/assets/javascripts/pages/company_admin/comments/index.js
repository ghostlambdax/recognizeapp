window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_comments-index"] = (function() {
  'use strict';

  var Comments = function() {
    this.addEvents();
  };

  Comments.prototype.addEvents = function() {
    new R.CompanyAdmin();
  };

  Comments.prototype.removeEvents = function() {
  };

  return Comments;

})();
