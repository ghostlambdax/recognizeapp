window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_accounts_spreadsheet_importers-new"] = (function() {
  'use strict';

  var AccountsImporter = function() {
    this.addEvents();
  };

  AccountsImporter.prototype.addEvents = function() {
    var companyAdmin = new R.CompanyAdmin();
    this.bindAccountsSpreadSheetImporter();
  };

  AccountsImporter.prototype.bindAccountsSpreadSheetImporter = function() {
    var $container = $("#accounts_spreadsheet_importer");
    var uploader = new window.R.Uploader(
      $container,
      processDataSheet,
      {
        submitBtn: $container.find("input[type=submit]")
      }
    );
  };

  function processDataSheet(e, json) {
    $.ajax({
      url: json.process_data_sheet_endpoint,
      method: "PUT",
      contentType: "application/json",
      data: JSON.stringify({
        accounts_spreadsheet_import_import_service: {
          update_only: $("#accounts_spreadsheet_import_import_service_update_only").is(':checked'),
          remove_users: $("#accounts_spreadsheet_import_import_service_remove_users").is(':checked')
        }
      })
    });
  }

  return AccountsImporter;
})();
