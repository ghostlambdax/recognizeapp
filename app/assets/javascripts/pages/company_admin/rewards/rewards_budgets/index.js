window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_rewards_budgets-index"] = (function() {
  'use strict';

  var CASH_REQUEST_INPUT = "#points_requester_amount";

  var RPI = function() {
    this.pointsConversion = parseInt( $("#pointsConversion").text() );
    this.deficitAmount = parseFloat( $("#deficitAmount").data("deficit")).toFixed(2);
    this.addEvents();
    this.updateTotal();
  };

  RPI.prototype.addEvents = function() {
    new R.CompanyAdmin();

    $document.on("keyup mouseup", CASH_REQUEST_INPUT, this.updateTotal.bind(this));

    $("#new_buy_points").on("ajaxify:success", this.successPointsRequest);
  };


  RPI.prototype.removeEvents = function() {
    $document.off("keyup", CASH_REQUEST_INPUT, this.updateTotal.bind(this));
  };

  RPI.prototype.successPointsRequest = function() {
    Swal.fire("Points Requested", "The Recognize team has received your request to deposit. We'll reach out shortly", "success");
  };

  RPI.prototype.updateTotal = function() {
    var price = parseFloat( $(CASH_REQUEST_INPUT).val(), 2 ),
        points,
        feePercentage,
        feeAmountAsDecimal,
        feeTotal,
        totalPrice;

    if (price < 0 || isNaN( price )) {
      price = 0;
    }

    points = price * this.pointsConversion;
    feePercentage = parseInt( $("#purchasingFeePercentage").text() );
    feeAmountAsDecimal = feePercentage * 0.01;
    feeTotal = price * feeAmountAsDecimal;

    totalPrice = price + feeTotal;

    $(".purchasingAmount").text(R.utils.formatCurrency(price, {includeSymbol: false}));
    $(".purchasingPoints").text(points.toLocaleString());
    $(".purchasingFee").text(R.utils.formatCurrency(feeTotal, {includeSymbol: false}));
    $(".purchasingTotal").text(R.utils.formatCurrency(totalPrice, {includeSymbol: false}));

    this.updateSidebar(points, price);
  };

  RPI.prototype.updateSidebar = function(points, price) {
    var currentPoints = parseInt( $("#currentPoints").data('current-points') );
    var newPoints = currentPoints + points;
    var currentAmount = parseFloat( $("#currentAmount").data('current-amount') );
    var deficitAmount = this.deficitAmount - price;

    if (deficitAmount <= 0) {
      $("#deficitAmountWrapper").removeClass("warning");
      $(".deficitPoints").text(0);
      $(".deficitAmount").text(0);
    } else {
      $(".deficitPoints").text(Math.round(deficitAmount * this.pointsConversion).toLocaleString());
      $(".deficitAmount").text(R.utils.formatCurrency(deficitAmount, {includeSymbol: false}));
      $("#deficitAmountWrapper").addClass("warning");
    }

    $(".purchasingAmount").text(R.utils.formatCurrency(price, {includeSymbol: false}));
    $(".purchasingPoints").text(points.toLocaleString());

    $(".newPoints").text(newPoints.toLocaleString());
    $(".newPrice").text(R.utils.formatCurrency((currentAmount + price), {includeSymbol: false}));
  };

  return RPI;
})();
