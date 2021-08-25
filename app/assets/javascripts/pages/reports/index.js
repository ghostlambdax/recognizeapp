window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["reports-index"] = (function($, window, undefined) {
  return function() {
    this.pagelet = new window.R.Pagelet();
    this.dateRange = new window.R.DateRange({refresh: 'turbolinks'});

    $("#yammer_stats").click(function (e) {
      e.preventDefault();
      $("#leaderboard_filters").hide();
      document.location.hash = "yammer";
    });

    $("#recognize_stats").click(function (e) {
      e.preventDefault();
      $("#leaderboard_filters").show();
      document.location.hash = "recognize";
    });

    if (document.location.hash == "#yammer") {
      $("#yammer_stats").trigger("click");
    }
  }
})(jQuery, window);
