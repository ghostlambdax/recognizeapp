window.R = window.R || {};
window.R.ui = window.R.ui || {};

window.R.setupKiosk = function() {
  var waitOnDetailView = 7000;
  var waitOnKiosk = 2000;
  var storageKey = "currentKioskItem";

  if (window.R.setupKiosk.enabled) {return;}

  function loop() {

    var nextItem = window.localStorage[storageKey] ? parseInt(window.localStorage[storageKey]) : -1;

    nextItem += 1;

    var $recognition = $("#stream .recognition-card").eq(nextItem);
    var offset = 0;

    if (!$recognition.length) {
      nextItem = 0;
      $recognition = $("#stream .recognition-card").eq(nextItem);
    }

    offset = $recognition.offset().top;

    $("html, body").animate({
      scrollTop: (offset - 100) +"px"
    });

    $recognition.addClass("kioskSelected");

    setTimeout(function() {
      $recognition.removeClass("kioskSelected");
      loop();
    }, waitOnDetailView);

    window.localStorage[storageKey] = nextItem;
    window.R.setupKiosk.enabled = true;
  }

  setTimeout(function() {
    loop();
  }, waitOnKiosk);
};

window.R.setupKiosk.enabled = false;

/*
 * Stream.js
 * This script is used by the default stream page as well as grid page
 **/
window.R.ui.Stream = (function($, window, body, R, undefined) {
  var COLUMN_SWITCH_ELEMENT = ".column-switch";

  function isDesktop() {
    return window.outerWidth > 768;
  }

  var Stream = function(opts) {

    opts = opts || {};
    var layoutMode = 'fitRows';

    window.R.utils.listenForWindowMessage();

    this.gridMode = !!opts.grid;
    this.$container = $('#stream');
    this.teamsPaginationPath = ".team-paginate .pagination .next_page";
    // there are two different list elements for mobile and desktop
    this.$filterByLists = $('.filter-by-list');

    if (this.gridMode) {

      // Kiosk / grid mode
      layoutMode = 'masonry';

      // this is needed for Turbolinks requests because TL only replaces the <body>
      $html.addClass('fullscreen');

      if (window.location.href.indexOf("animate=false") === -1) {
        window.R.setupKiosk();
      }
    } else {
      // Stream page

      // needed when navigating back from grid page
      $html.removeClass("fullscreen");

      this.comments = new R.Comments();
      this.buttons = new R.ui.Buttons();
      this.$teamList = $("#team-list");

      if (isDesktop()) {
        this.fixStreamHeight();
      }

      if (isDesktop() && this.$teamList.length > 0) {
        this.initTeamInfiniteScroll(true);
      }
    }

    this.initCards(layoutMode);

    this.addEvents();
  };

  Stream.prototype.initCards = function(layoutMode) {
    layoutMode = layoutMode || 'fitRows';
    this.recognitionCards = new R.Cards("#stream", function() {}, {
      layoutMode: layoutMode,
      gridView: this.gridMode
    });
  };

  // if the last pagination link is disabled, it means end of pagination has been reached
  Stream.prototype.teamPaginationExhausted = function() {
    return this.$teamList.find('.pagination .next_page').last().hasClass('disabled');
  };

  Stream.prototype.initTeamInfiniteScroll = function(prefill) {
    var that = this;
    var nextPageSel = this.teamsPaginationPath;

    if (this.$teamList.find('.pagination').length === 0 ||    // no pagination from server
        this.teamPaginationExhausted()) {                     // pagination exhausted in previous visit
      return;
    }

    this.$teamList.infiniteScroll({
      elementScroll: isDesktop(),
      path: nextPageSel,
      append: "li",
      prefill: prefill || isDesktop(),
      responseType: 'document',
      scrollThreshold: 200,
      loadOnScroll: true,
      history: false, // 'replace',
      historyTitle: false,
      hideNav: false,
      status: false,
      button: false,
      debug: true,
      checkLastPage: true,
      outlayer: {
        appended: function (newElements) {
          if (that.teamPaginationExhausted()) {
            that.$teamList.infiniteScroll('destroy');
          }

          // remove previous pagination element so the updated link is referenced on turbolinks page restore.
          // also @see Cards.js & users-index.js for alternative fix where href is updated for all pagination links
          $(nextPageSel).first().closest('.team-paginate').remove();
        }
      }
    });

    $document.one("turbolinks:before-cache", function(){
      R.utils.destroyInfiniteScroll(this.$teamList);
    }.bind(this));
  };

  Stream.prototype.fixStreamHeight = function() {
    var offsetY = this.$container.offset().top;
    var windowHeight = $window.height();
    var cssObj = {height: (windowHeight - offsetY)+"px"};
    var $teamList = $("#team-list");
    //
    this.$container.css(cssObj);

    if ($teamList.length) {
      cssObj = {height: (windowHeight - $teamList.offset().top)+"px"};
      $teamList.css(cssObj);
    }
  };

  Stream.prototype.resetStreamHeight = function() {
    this.$container.css({height: '100%'});
    this.$teamList.css({height: 'auto'});
  };

  // pagination link can be missing / disabled (with undefined href) if pagination is not needed / has been exhausted
  Stream.prototype.canPaginateTeams = function() {
    return !!$(this.teamsPaginationPath).attr('href');
  };

  /**
   * This reset fixes the issue where the screen is resized from short to long screen,
   *   and the team list loses the scroll bar, breaking the pagination behavior
   */
  Stream.prototype.resetTeamListInfiniteScrollIfNeeded = function() {
    var $teamList = this.$teamList;
    if (!this.canPaginateTeams() || !$teamList.is(':visible'))
      return;

    if ($teamList.data('infiniteScroll')) {
      R.utils.destroyInfiniteScroll($teamList);
      this.initTeamInfiniteScroll(true);
    }
  };

  Stream.prototype.addEvents = function() {
    var resizeTimer = 0;
    var waitOnResizeBeforeHeightAdjustment = 1000;

    if (!this.gridMode) {
      $window.on('resize.stream', function() {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function() {

          if (isDesktop()) {
            this.fixStreamHeight();
          } else {
            this.resetStreamHeight();
          }

          this.resetTeamListInfiniteScrollIfNeeded();
        }.bind(this), waitOnResizeBeforeHeightAdjustment);

        if($('.left-column').data('ms_teams') === true && window.innerHeight >= 769) {
          $('.left-column').addClass('width0');
        } else {
          $('.left-column').removeClass('width0');
        }

      }.bind(this));

      $document.on("resize:infiniteReset", function() {
        NProgress.done();
        // Only reinitialize the team scroll
        if (this.canPaginateTeams()) {
          R.utils.destroyInfiniteScroll(this.$teamList);
          delete this.$teamList.infiniteScroll;

          // this re-init must be done after the resize height adjustment above (which does not happen immediately),
          // or else it causes mass pagination requests
          setTimeout(function () {
            this.initTeamInfiniteScroll();
          }.bind(this), waitOnResizeBeforeHeightAdjustment + 200);
        }
      }.bind(this));

      // On tab change
      $document.on(R.touchEvent, COLUMN_SWITCH_ELEMENT, this.toggleDetails.bind(this));
      // When a user clicks the Team link on the left to show the recognitions for that team.
      $document.on(R.touchEvent, "#team-list .link", this.goToTeam.bind(this));
      $document.on(R.touchEvent, '.filter-by-list a', this.filterBy.bind(this));
    }
  };

  Stream.prototype.goToTeam = function(e) {
    var $this = $(e.target);
    var newURL = $this.prop("href");
    var selectedFilterBadges = $('.filter-by-list:visible li.selected');

    if(selectedFilterBadges.length === 1) {
      // assumes `filter_by[]` param is never present in these team links beforehand
      var badge = selectedFilterBadges.first().parents('a').data('badge');
      newURL += newURL.indexOf('?') > -1 ? '&' : '?';
      newURL += window.R.utils.objectToParamString({'filter_by[]': badge});
    }
    e.preventDefault();
    this.pushHistoryAndLoadRecognitions(newURL, $this, {team: true});

    return false;
  };

  Stream.prototype.filterBy = function(e) {
    var $this = $(e.target).parents('a');
    var newURL = $this.prop('href');
    var teamId = $('#team-list .team-item.current .link').attr('id');
    var $desktopFilterLinks = $('.right-column .filter-by-list').find('a');
    var currentBadge = $this.data('badge');
    var queryParams = '';
    var that = this;
    var selectedBadgeCount = 0;

    // Either filter list can be chosen here for checking existing state, as the state is mirrored
    if ($this.find('li').hasClass('selected') && $desktopFilterLinks.find('li.selected').length === 1) {
      // this is the only selected filter and cannot be toggled
      e.preventDefault();
      return;
    }

    $desktopFilterLinks.each(function() {
      // Previous condition of filter's badge before the current action.
      var isSelected = $(this).find('li').hasClass('selected');
      var badge = $(this).data('badge');

      if ((isSelected && currentBadge !== badge) || (!isSelected && currentBadge === badge)) {
        queryParams = that.addBadgeToParams(queryParams, badge);
        selectedBadgeCount += 1;
      }
    });

    if (selectedBadgeCount !== 2) {
      newURL += newURL.indexOf('?') > -1 ? '&' : '?';
      newURL += queryParams;
    }

    if(typeof(teamId) != 'undefined') {
      teamId = teamId.replace(/team-/, '');
      newURL += newURL.indexOf('?') > -1 ? '&' : '?';
      newURL += 'team_id=' + teamId;
    }
    e.preventDefault();
    this.pushHistoryAndLoadRecognitions(newURL, $this, {filter: true});

    return false;
  };

  Stream.prototype.removeEvents = function() {
    // delete this.$container;
    if (this.gridMode) {
      $html.removeClass('fullscreen');
    } else {
      // close team selection when exiting
      if (!isDesktop() && this.$teamList.is(':visible')) {
        this.toggleDetails();
      }

      $window.off('resize.stream');
      $document.off(R.touchEvent, COLUMN_SWITCH_ELEMENT);
      $document.off(R.touchEvent, "#team-list .link");
      $document.off(R.touchEvent, '.filter-by-list a');
      $document.off("resize:infiniteReset");
    }

    delete this.recognitionCards;
  };

  Stream.prototype.highlightCurrentTeamLink = function($this, opts) {
    var href = window.location.href;
    var params = R.utils.queryParams();
    var currentClass = 'current';

    if(opts['team']) {
      this.$teamList.find('li.' + currentClass).removeClass(currentClass);

      if ($this.length) {
        return $this.closest("li").addClass(currentClass);
      }

      if (href.indexOf("team_id") > -1) {
        $('#team-' + params['team_id']).closest("li").addClass(currentClass);
      } else {
        this.$teamList.find("li:first").addClass(currentClass);
      }
    }
  };

  Stream.prototype.highlightCurrentFilterLink = function($this, opts) {
    if(opts['filter']) {
      this.$filterByLists.find('a').each(function() {
        if ($(this).data('badge') === $this.data('badge')) {
          var isSelected = $(this).find('li').hasClass('selected');
          if(isSelected) {
            $(this).find('li').removeClass('selected');
          } else {
            $(this).find('li').addClass('selected');
          }
        }
      });
    }
  };

  Stream.prototype.loadRecognitionPage = function($this, opts) {
    var newURL = window.location.href;

    if (this.$container.data('infiniteScroll'))
      this.$container.infiniteScroll('abortLoadNextPage');

    NProgress.start();

    this.$container.addClass('loading');
    if (this.recognitionCards) { this.recognitionCards.unload(); }
    this.loadCachedCardsForPreviewIfPresent();

    this.$container.load(newURL + " .recognition-card", null, function(response, status, xhr) {
      NProgress.done();
      this.$container.removeClass('loading').scrollTop(0);

      this.initCards();
    }.bind(this));

    if ($window.width() <= 768) {
      this.toggleDetails();
    }

    this.highlightCurrentTeamLink($this, opts);
    this.highlightCurrentFilterLink($this, opts);
    this.updateGridLink(newURL);
  };

  /*
   * Experimental!
   * Load cards from Turbolinks cache while request is pending (if cache exists for requested page)
   * This is similar to Turbolinks' own behavior, but only applies to the cards container
   *
   * Note: This does not initCards(), being a momentary preview. That would also involve some further complexity.
   **/
  Stream.prototype.loadCachedCardsForPreviewIfPresent = function() {
    var snapshot = Turbolinks.controller.getCachedSnapshotForLocation(Turbolinks.controller.location);
    if (snapshot && snapshot.body) {
      var cachedContainer = $(snapshot.body).find('#stream');
      if (cachedContainer.length) {
        this.$container.html(cachedContainer.clone().children());
        this.$container.removeClass('loading');
      }
    }
  };

  Stream.prototype.toggleDetails = function(e) {
    var $details = $("#recognition-details");
    var containerWatch, teamWatch;

    if (e) {e.preventDefault();}

    $details.toggleClass("block width100");
    $(COLUMN_SWITCH_ELEMENT).toggleClass("block");
    this.$container.toggleClass("displayNone");

    if (this.$container.hasClass('displayNone')) {
      containerWatch = 'disableScrollWatch';
      teamWatch = 'enableScrollWatch';

    } else {
      containerWatch = 'enableScrollWatch';
      teamWatch = 'disableScrollWatch';
    }

    if (this.$container.data('infiniteScroll')) {this.$container.infiniteScroll(containerWatch);}

    var scrollCheckedKey = 'infiniteScrollInitializedForFirstTime';
    if (!this.$teamList.data(scrollCheckedKey)) { // first time
      this.initTeamInfiniteScroll(true);
      this.$teamList.data(scrollCheckedKey, true);
    } else if (this.$teamList.data('infiniteScroll')) {
      if (teamWatch === 'enableScrollWatch') {
        this.resetTeamListInfiniteScrollIfNeeded();
      }

      this.$teamList.infiniteScroll(teamWatch);
    }

    if(!isDesktop()) {
      $('.left-column').removeClass('width0');
    }
  };

  /*
   * Update grid link URL when switching team.
   * using manual regex capture / replace instead of modern URL() API in order to support IE
   * alternatively, the grid path can be passed from the server as a data attr for each team item
   **/
  Stream.prototype.updateGridLink = function(newURL) {
    var $gridEl = $('#grid-link');
    var currentGridUrl = $gridEl.attr('href');
    var newGridUrl = '';

    if (typeof(currentGridUrl) === 'undefined') {
      return;
    }

    newGridUrl = currentGridUrl.replace(/(&?filter_by%5B%5D=\w+)+/, '');
    newGridUrl = newGridUrl.replace(/&?team_id=\w+/, '');

    if(newURL.indexOf('?') > -1) {
      newGridUrl += newGridUrl.indexOf('?') > -1 ? '&' : '?';
      newGridUrl += newURL.substr(newURL.indexOf('?') + 1);
    }

    $gridEl.attr('href', newGridUrl);
  };

  Stream.prototype.pushHistoryAndLoadRecognitions = function(url, $targetEl, opts) {
    pushHistoryWithTurbolinks(url);
    this.loadRecognitionPage($targetEl, opts);
  };

  Stream.prototype.addBadgeToParams = function(params, badge) {
    params += params.length != 0 ? '&' : '';
    params += window.R.utils.objectToParamString({'filter_by[]' : badge});
    return params;
  };

  /*
   * This can be used instead of history.pushState() for Turbolinks backward navigation compatibility
   * Caches current page, pushes history with Turbolinks state object, and updates Turbolinks last location
   */
  function pushHistoryWithTurbolinks(newURL) {
    var ctrl = Turbolinks.controller;

    // manually cache snapshot so that new request is not needed on (first) restore of the current page
    // This is extracted from ctrl.cacheSnapshot(), without the `before-cache` event trigger (which removes events)
    if (ctrl.shouldCacheSnapshot()) {
      ctrl.cache.put(ctrl.lastRenderedLocation, ctrl.view.getSnapshot().clone());
    }

    /*
     * Push history with Turbolinks state information
     *
     * This is the crucial part:
     *   without the :turbolinks key in the corresponding history.state, this page will be ignored by turbolinks on restore
     * ref (enhancement ticket): https://github.com/turbolinks/turbolinks/issues/219#issuecomment-424817249
     **/
    ctrl.pushHistoryWithLocationAndRestorationIdentifier(newURL, Turbolinks.uuid());

    // Need to manually update this state variable
    // so that when visiting some other page from stream page after selecting another team,
    // the last visited team page is cached for its corresponding URL instead of the first visited team URL
    ctrl.lastRenderedLocation = Turbolinks.Location.wrap(newURL);
  }

  return Stream;
})(jQuery, window, document.body, window.R);
