(function() {

  var cards = [];
  var tabLinkSelector = '.nav-pills li a';

  var tabToContentMap = {
    "#sent": '#profile-recognitions-sent',
    "#received": '#profile-recognitions-received',
    "#recognition-tab": "#profile-recognitions-received",
    "#achievements-tag": "#recognitions-achievements"
  };

  function getTabElementByHash(hash) {
    return $(tabLinkSelector + '[href="' + hash + '"]');
  }

  function loadTabFromAnchorWithDefault() {
    var hash = window.location.hash;
    var tabEl;

    if (hash) {
      var targetTabEl = getTabElementByHash(hash);
      if (targetTabEl.length) {
        tabEl = targetTabEl;
      }
    }

    if (!tabEl) { // default fallback
      hash = '#received';
      tabEl = getTabElementByHash(hash);
    }

    tabEl.tab('show');

    if (tabToContentMap[hash]) {
      loadCards(tabToContentMap[hash]);
    }
  }

  window.R = window.R || {};
  window.R.pages = window.R.pages || {};

  window.R.pages["users-show"] = function() {
    loadTabFromAnchorWithDefault.call(this);

    this.pagelet = new window.R.Pagelet();

    var resizeTimer;
    var child = '.recognition-card';

    this.addEvents();

    this.comments = new R.Comments();
  };

  window.R.pages["users-show"].prototype = {
    addEvents: function() {
      var that = this;

      $document.on('click', '.direct-report-trigger', function(e) {
        e.preventDefault();
        $('#direct-reports-user-tab a').click();
      });

      $document.on('click', ".view-reward-details", this.viewRewardDetails);

      addEventForParentRecognitionTabNav();
      addEventForChildRecognitionTabNavs();

      
      $document.on('click', tabLinkSelector, function (e) {
        e.preventDefault();
        history.pushState({}, '', this.href);
      });

      $document.on('click', '.user-profile-navbar-wrapper .nav li a:not(.recognition-nav-item)', function(e) {
        turnOffWatching();
      });
    },
    removeEvents: function() {
      $('#recognition-tab a[data-toggle="tab"]').off('shown');
      $("#user_slug").off("keyup");
      $document.off('click', tabLinkSelector);
      $document.off('click', '.user-profile-navbar-wrapper .nav li a:not(.recognition-nav-item)');
    },

    viewRewardDetails: function(e) {
      var $this = $(this), instructions;
      var data = {
        instructions: $this.data('instructions'),
        title: $this.data('title')
      };

      if ($this.data("extrainfo")) {
        data.extraInfo = $this.data("extrainfo");
      }

      if ($this.data("redemption-additional-instructions")) {
        data.redemptionAdditionalInstructions = $this.data("redemption-additional-instructions");
      }

      instructions = Handlebars.compile( $("#redemptionDetails").html() )(data);

      Swal.fire({
        html: instructions,
        customClass: 'redemptionSwal',
        showCancelButton: false,
        confirmButtonText: gon.okay
      });
    }
  };

  function turnOffWatching() {
    cards.forEach(function(card){
      if (card &&
          card.$container &&
          card.$container.infiniteScroll &&
          card.$container.data('infiniteScroll')) {
        card.$container.infiniteScroll('disableScrollWatch');
      }
    });
  }

  function loadCards(el) {
    var $el = $(el);
    // since multiple scroll dont work properly pause one when other is active
    turnOffWatching();

    var initCards = function() {
      cards.push(new R.Cards($el, null, {
        infiniteScrollPath: "#recognition-tab .active.tab .pagination .next_page",
        history: false
      }));
      $el.data("loaded", true);
    };

    if ($el.find(".recognition-card").length > 0 && $el.data("loaded") !== true) {
      initCards();
    } else {
      $el.unbind("pageletLoaded") // clear bindings from previous navigation
        .bind("pageletLoaded", function () {
          if ($el.find(".recognition-card").length > 0) {
            initCards();
          }
        });
    }

    // multiple scroller have effect of changing states
    // resetting the pause and done status for the current one
    if ($el.data('infiniteScroll')) {
      $el.infiniteScroll("enableScrollWatch");
    }

    if ($el.data("loaded")) {
      if($el.hasClass('isotope')) {
        $el.isotope("reLayout");
      }
    }
  }

  // handler to init cards when switching to parent recognition tab
  // this is needed because the active child tab's event is not invoked in this case as it wasn't clicked directly
  //
  //   IF the parent recognition tab was not active on page load (i.e. when some other tab was anchored in the URL)
  //   AND this is the first switch to this tab
  //     loadCards() hasn't been invoked yet
  //   ELSE
  //     loadCards() still needs to be invoked again on every switch in order to resume infinite scrollwatch
  //
  function addEventForParentRecognitionTabNav() {
    // note: this event does not fire for initial load,
    //       which is preferred behavior, as that case is already being handled from loadTabFromAnchorWithDefault()
    $('.recognition-nav-item').on("shown", function () {
      $('#recognition-tab .active > a[data-toggle="tab"]').trigger('shown');
    });
  }

  function addEventForChildRecognitionTabNavs() {
    $('#recognition-tab a[data-toggle="tab"]').on("shown", function (e) {
      var href = e.target.getAttribute("href");
      var el;

      try {
        el = tabToContentMap[href];
      } catch (e) {
        return;
      }

      loadCards(el);
    });
  }

})();
