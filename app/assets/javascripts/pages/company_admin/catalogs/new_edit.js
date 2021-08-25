window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_catalogs-new"] = window.R.pages["company_admin_catalogs-edit"] = (function() {
  "use strict";

  var Catalog = function() {
    this.addEvents();
  };

  Catalog.prototype.addEvents = function() {
    new R.CompanyAdmin();
    this.bindRolesSelect();
    this.bindCurrencySelect2();
    this.bindRatioHinter();
  };

  Catalog.prototype.removeEvents = function() {
    // preserve tag/role selections on page restore
    var id = $('#new_catalog').length > 0 ? '#new_catalog' : '#edit_catalog';
    R.utils.saveSelectValuesToDom(id);
  };

  Catalog.prototype.bindRolesSelect = function() {
    new window.R.Select2(function () {
      $('.company-role-select').select2({
        tokenSeparators: [',', ' ']
      });
    });
  };

  Catalog.prototype.bindCurrencySelect2 = function() {
    new window.R.Select2(function(){
      $("#catalog_currency").select2();
    });
  };

  // does not need equivalent unbind function, as the relevant elements are non-global (thus non-persisted)
  Catalog.prototype.bindRatioHinter = function() {
    initializeRatioHint();
    $('#catalog_points_to_currency_ratio').on('input', updateRatioHint);
    $('#catalog_currency').on('change', updateRatioTexts);
  };

  function initializeRatioHint() {
    $('#ratio-hint').removeClass('hidden');
    updateRatioTexts();
  }

  function updateRatioHint(_event) {
    var ptcScale = Math.pow(10, 5); // pointsToCurrency ratio scale in db (5)
    var ratioHint = '';
    var currencySymbol = $('#catalog_currency').find(':selected').text().trim().split(' ')[0];
    if (currencySymbol !== 'Select') { // "Select a currency"
      var pointsToCurrencyRatio= parseFloat( $('#catalog_points_to_currency_ratio').val() );
      if (!isNaN(pointsToCurrencyRatio) && pointsToCurrencyRatio> 0) {
        // this value is rounded by Rails as well beyond max scale in the db column
        var roundedPointsToCurrencyRatio = Math.round(pointsToCurrencyRatio * ptcScale) / ptcScale;
        if (roundedPointsToCurrencyRatio > 0) {
          var pointsToCurrencyRatio = 1 / roundedPointsToCurrencyRatio;
          // this rounding is just for displaying compactly
          var roundedCurrencyToPointsRatio = Math.round(pointsToCurrencyRatio * ptcScale) / ptcScale;
          if (roundedCurrencyToPointsRatio) {
            ratioHint = '1 pt = ' +currencySymbol + roundedCurrencyToPointsRatio;
          }
        }
      }
    }
    $('#ratio-hint').text(ratioHint);
  }

  function updateRatioLabel(_event) {
    var ratioCurrencyLabel= '';
    var currencySymbol = $('#catalog_currency').find(':selected').text().trim().split(' ')[0];
    if (currencySymbol !== 'Select') { // "Select a currency"
      ratioCurrencyLabel= currencySymbol;
    }
    $('#ratio-currency-symbol').text(ratioCurrencyLabel);
  }

  function updateRatioTexts(_event) {
    updateRatioHint(_event);
    updateRatioLabel(_event);
  }
  return Catalog;
})();
