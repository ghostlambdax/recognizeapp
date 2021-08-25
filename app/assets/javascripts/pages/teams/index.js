window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["teams-index"] = (function() {
  var tableSelector = '#teams-directory > table tbody';
  var paginationLinkSelector = '.pagination .next_page';
  var perPage = 10;

  var TeamsIndex = function() {
    this.teams = new window.Teams.Inline();
    this.$table = $(tableSelector);
    this.favoriteTeam = this.setupFavoriteTeam();
    this.addEvents();
  };

  TeamsIndex.prototype.addEvents = function() {
    var $directoryWrapper = $("#teams-directory-wrapper");
    var teamsDirectoryId = "#teams-directory";
    var $teams = $("#teams");

    $teams
      .on("ajax:beforeSend", function(evt, xhr, _opts){
        var newName = $(evt.target).find("input[type=text]").val();

        if(!newName.trim()) {
          xhr.abort();
          return false;
        }

        var teamNames = $("#teams-directory .name h3").map(function(){return $(this).html().toLowerCase();});

        if($.inArray(newName.toLowerCase(), teamNames) > -1) {
          showDuplicationErrorMessage();
          xhr.abort();
          return false;
        }

      })
      .on("ajaxify:complete", function(e, xhr, response) {
        if (response.status === 200) {
          $directoryWrapper.load(window.location.href + " " + teamsDirectoryId, function(){
            this.addResGauge();
          }.bind(this));

          $("#add-team-input").attr("value", "");
          displayFeedback(gon.feedback_messages.team_created, $("#inner-add"));
        } else {
          // teams are lazy loaded now so there can be duplicate teams that aren't in the current page
          // thus 'bypassing' the initial duplication check in frontend
          showDuplicationErrorMessage();
        }
      }.bind(this));

    // re-fetch the team list from server when a team is joined / left.
    $directoryWrapper.on("ajax:success", "a.team-toggle", function(evt, xhr, opts){
      R.utils.destroyInfiniteScroll(this.$table);

      $directoryWrapper.load(window.location.href + " " + teamsDirectoryId, function() {
        this.addResGauge();
        this.$table = $(tableSelector);
        this.bindInfiniteScrollIfNeeded();
        feather.replace();
      }.bind(this));
      return false;
    }.bind(this));

    $document.on( 'request.infiniteScroll', tableSelector, function( _event, _path ) {
      NProgress.start();
    });

    this.addResGauge();
    this.bindInfiniteScrollIfNeeded();
  };

  TeamsIndex.prototype.removeEvents = function() {
    $("#new_team").unbind("ajaxify:complete");
    this.teams.removeEvents();

    R.utils.destroyInfiniteScroll(this.$table);
    $document.off('request.infiniteScroll');
    this.favoriteTeam.removeEvents();
  };

  TeamsIndex.prototype.addResGauge = function() {
    var $resScores = $(".res-score");
    if ($resScores.children().length > 0) {
      $resScores.empty();
    }
    window.R.gage(".res-score");
  };

  TeamsIndex.prototype.bindInfiniteScrollIfNeeded = function() {
    var otherTeamsCount = this.$table.find('tr.other_team');
    // the pagination element is absent if there are insufficient elements for pagination
    // also, the pagination link is null in an edge case when returning to page after pagination was previously complete
    if ($(paginationLinkSelector).attr('href')) {
      this.setupInfiniteScroll();
    }
  };

  TeamsIndex.prototype.setupInfiniteScroll = function() {
    this.$table.infiniteScroll({
      path: paginationLinkSelector,
      scrollThreshold: 600,
      append : '#teams-directory tr.other_team',
      errorCallback: NProgress.done,
      outlayer: {
        appended: function (newElements) {
          var $table = $(tableSelector);
          NProgress.done();

          // Fix to manually stop infinite scroll when no further cards present.
          if (newElements.length < perPage) {
            $table.infiniteScroll('destroy');
          }
        }
      },
      elementScroll: false,
      loadOnScroll: true,
      history: true, // 'replace',
      historyTitle: true,

      hideNav: false,
      status: false,
      button: false
    });

    // update the next pagination url in DOM so that it is preserved on turbolinks page restore.
    this.$table.on( 'load.infiniteScroll', function( event, response, _currentPath ) {
      var nextPath = $(response).find(paginationLinkSelector).attr('href') || null;
      $(paginationLinkSelector).attr('href', nextPath);
    }.bind(this));

    this.$table.on( 'append.infiniteScroll', function( event, response, _currentPath ) {
      this.addResGauge();
    }.bind(this));

  };
  TeamsIndex.prototype.setupFavoriteTeam = function() {
    return new window.R.ui.FavoriteTeam();
  };



  function showDuplicationErrorMessage() {
    displayFeedback(gon.feedback_messages.duplicate_team, $("#inner-add"), 'text-warn');
  }

  function displayFeedback(message, element, msgClass){
    var msgClass = msgClass || 'text-success';
    var $existingMessages = element.find(".team-create-success");
    $existingMessages.remove();
    var successMessage = '<span class="team-create-success '+msgClass+'">' + message + '</span>';
    element.append(successMessage);
    element.find(".team-create-success").fadeOut(4000);
  }

  return TeamsIndex;

})();