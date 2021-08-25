window.R = window.R || {};
window.R.pages = window.R.pages || {};

(function() {
  var S = function() {
    initDataTable();
  };

  S.prototype.removeEvents = function() {
  };

  function initDataTable() {

    $.getScript( "/assets/datatables.js", function( ) {

      $('table').DataTable( {
        ordering: true,
        paging: true,
        searching: true,
        responsive: false,
        pageLength: 100
      });
    });

  }

  window.R.pages["admin_subscriptions-index"] = S;
})();

