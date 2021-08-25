(function() {
  var pageID,
      slaveObject = {},
      xdomain = Recognize.xdomain,
      praiseTimer = 0,
      praiseCounter = 0,
      isLoading = false,
      loadTimer = 0,
      userProfileTimer,
      hasStarted = false;

  Recognize = Recognize || {};

  Recognize.host = window.localStorage.recognizeYammerHost || "//recognizeapp.com";

  Recognize.removePraise = function() {
    var $praise = jQuery("[data-name='praisePublisher']");
    clearTimeout(praiseTimer);
    if ($praise.length === 0 && praiseCounter < 100) {
      praiseCounter++;
      praiseTimer = setTimeout(function() {
        Recognize.removePraise();
      }, 500);
    } else {
      try {
        $praise.remove();
      } catch(e) {}

    }
  };

  if (xdomain) {
    slaveObject["https:"+Recognize.host] = "/proxy.html";
    xdomain.slaves(slaveObject);
  }

  function auth(currentYammerUsername) {
    var pingingAuthentication,
        dataForPing = currentYammerUsername ? {username: currentYammerUsername} : {},
        el1 = jQuery("<div>"),
        feed,
        counter = 6;

    if (isLoading === true) {
      return;
    }

    isLoading = true;

    Recognize.patterns.overlay.init();

    Recognize.removePraise();

    Recognize.patterns.toolbar.create();

    // Has it started to load and is now loading? Not anymore.
    hasStarted = false;
    isLoading = false;

  }

  Recognize.init = function() {
    var stylesheet,
        href = window.location.href,
        $profile;

    Recognize.removePraise();

    if (!href.match(/yammer.com/) && href.match(/recognizeapp.com/)) {
      jQuery("#notice.yammer").remove();
    } else {

      Recognize = Recognize || {};

      window.$body = window.$body || jQuery('body');

      //
      // stylesheet = document.createElement("link");
      // stylesheet.setAttribute("href", Recognize.host + "/assets/extension.css");
      // stylesheet.setAttribute("rel", "stylesheet");
      // stylesheet.setAttribute("type", "text/css");
      // $body.append(stylesheet);

      // Recognize.file = new Recognize.patterns.File();

      pageID = $body.attr('id');
      Recognize.pageID = pageID;

      auth();
    }
  };

  Recognize.path = function(path) {
    return Recognize.host+"/"+path;
  };

  loadDepedencies();

  jQuery(document).off("click.recognize", "#column-one a");

  jQuery(document).on("click.recognize", "#column-one a, .yj-feed-choices li, .yj-lightbox-content a", function() {
    reload();
  });

  // Always making sure that if things are loaded, they will soon.
  setInterval(function() {
    if (!isLoading && !hasStarted) {
      reload();
    }
  }, 4000);

  function loadDepedencies() {
    if (!!document.getElementById("root")) {
      // Yammer 2020 redesign update



      loadTimer = setTimeout(function() {
        if (jQuery('[class*=leftSidebarColumn] [class*=mainSection]').length === 0) {
          loadDepedencies();
        } else {
          clearTimeout(loadTimer);

          Recognize.patterns.overlay.init();
          Recognize.patterns.toolbar.create();

          // Has it started to load and is now loading? Not anymore.
          hasStarted = false;
          isLoading = false;
        }
      }, 1000);

    } else {
      loadRecognize();
    }



  }

  function watchDom(run) {
    var observer, config;

    // select the target node
    var target = document.querySelector('#column-two');
    var columnOne = document.querySelector('#column-one');


    if (!target || !columnOne || !window.MutationObserver) {
      return;
    }

    // create an observer instance
    observer = new MutationObserver(function(mutations) {
      reload();
    });

    // configuration of the observer:
    config = { attributes: true, childList: true, characterData: false };

    // pass in the target node, as well as the observer options
    observer.observe(target, config);
    observer.observe(columnOne, config);
  }

  function reload() {
    // Is there the dom there necessary to attach a missing side bar R?
    if (jQuery("#column-one .yj-global-sidebar--top-nav .yj-nav-menu--primary-actions").length && jQuery("#recognize-list-sidebar").length === 0) {
      loadRecognize();
      // Is there the main column row of options and recognize isn't there?
    } else if (jQuery("#column-two .yj-global-publisher-switcher").length && jQuery("#recognize-list").length === 0) {
      loadRecognize();
    }
  }

  function loadRecognize() {
    hasStarted = true;
    isLoading = false;
    clearTimeout(loadTimer);
    loadTimer = setTimeout(function() {
      if (jQuery("#column-one .yj-global-sidebar--top-nav .yj-nav-menu--primary-actions").length > 0 || jQuery("#column-two .yj-global-publisher-switcher").length > 0) {
        clearTimeout(loadTimer);
        Recognize.init();
        watchDom(true);
      } else {
        loadRecognize();
      }
    }, 100);
  }

  Recognize.removePraise();
})();
