window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["teams-show"] = (function() {
  var gauge = false;
  
  var TeamsShow = function() {
    var timer = 0;
    var $recognitionWrapper = $("#recognitions-wrapper");
    this.favoriteTeam = this.setupFavoriteTeam();
    this.comments = new R.Comments();
    this.pagelet = new R.Pagelet();
    
    if ( $recognitionWrapper.find("li").length > 0) {
      new R.Cards( $("#recognitions-wrapper"), null, {infiniteScrollPath: ".pagination .next_page"});
    }
    
    window.R.ui.remoteOverlay();
    
    $(window).resize(function() {
      clearTimeout(timer);
      timer = setTimeout(function() {
        $document.trigger("recognition:change");
      }, 50);

    });

    if ($window.width() > 768) {
      gauge = window.R.gage("#team-res");
    }

    $document.on(R.touchEvent, "#column-switch", this.toggleDetails.bind(this));
  };

  TeamsShow.prototype.removeEvents = function() {
    $document.off(R.touchEvent, "#column-switch");
    // empty the graph on page leave
    $("#team-res").empty();
    gauge = false;
    this.favoriteTeam.removeEvents();
  };


  TeamsShow.prototype.toggleDetails = function(e) {
    var $details = $("#team-details");
    var text = "View details";
    e.preventDefault();
    $details.toggleClass("block");
    $(".default-view").toggleClass("displayNone");

    if (!gauge) {
      gauge = window.R.gage("#team-res");
    }

    if ($details.hasClass("block")) {
      text = "Close details";
    }

    $(e.target).text(text);
  };

  TeamsShow.prototype.setupFavoriteTeam = function() {
    return new window.R.ui.FavoriteTeam();
  };

  return TeamsShow;

})();