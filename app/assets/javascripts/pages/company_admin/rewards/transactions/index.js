window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_rewards_transactions-index"] = (function() {
  'use strict';

  var Tr = function() {
    new R.CompanyAdmin();
    this.addEvents();
  };

  Tr.prototype.addEvents = function() {
    if (gon.balance_info) {
      var balanceInfoElem = '<h3 class="txn-available-balance">' + gon.balance_info + '</h3>';
      $('#transactions-table_length').after(balanceInfoElem);
    }
  };

  return Tr;
})();