window.R.ready = false;

window.R.init = function() {
  'use strict';

  rLog('Start of init', window.R.ready);

  var hasTouch;
  var dataScript = document.body.getAttribute("id");

  if (window.R.ready) {
    return;
  }

  rLog('Start of nameSpace', R.nameSpace);
  R.nameSpace();

  var r = window.R || {};

  rLog('Start of browserDetector', window.R.utils.browserDetector);

  if (window.R.utils.browserDetector) window.R.utils.browserDetector();

  hasTouch = Modernizr.touch;

  rLog('Start of requiredToStart', R.isTurbo);

  requiredToStart();

  rLog('Start of loading page', window.R.currentPage);

  rLog('dataScript?', r.pages[dataScript]);

  if (r.pages[dataScript] && !window.R.currentPage) {
    window.R.currentPage = new r.pages[dataScript]();
  }

  rLog('Page ran');

  R.transition = new R.Transition();

  if (hasTouch) {
    $html.addClass("touch");
  }

  initTooltips();
  initCaptcha();

  $(window).load(function() {
    $body.addClass("ready");
  });


  if (!R.ui.sd && R.ui.ScheduleDemo) {
      R.ui.sd = new R.ui.ScheduleDemo();
  }

  $document.on(R.touchEvent, ".filters button", function() {
    var $this = $(this);
    $this.siblings().removeClass("selected");
    $this.addClass("selected");
  });

  $document.on(R.touchEvent, ".animate-scroll", function(e) {
    var $el = $(this), href, offset;

    e.preventDefault();

    if ($el.data("href")) {
      href =  $el.data("href");
    } else {
      href = $el.attr("href");
      $el.data("href", href);
    }

    $document.trigger('animate-scroll', $el);

    offset = $(href).offset().top;

    $("html, body").animate({
      scrollTop: (offset - 100) +"px"
    });
  });

  if (Modernizr.ie) {
    $('input[placeholder], textarea[placeholder]').placeholder().each(function() {
      var $this = $(this);
      if ($this.val() === $this.attr("placeholder")) {
        $this.val("");
      }
    });

  }

  $document.on(R.touchEvent, '.exportTable', function() {
    var $table = $(this).next("table");
    var filename = $table.data("filename");
    R.exportTableToCSV.apply(this, [$table, filename+".csv"]);
  });

  /*
   * Fix: Turbolinks 5 triggers a page visit for same-page anchor links (instead of just letting the browser 'jump')
   * https://github.com/turbolinks/turbolinks/issues/75
   *
   * Note: This fix originally broke the "back" behavior when coming back to anchored links
   * which has been partially mitigated later in this file with yet another fix: @see PR #1295
   */
  $document.on('turbolinks:click', function (event) {
    var target = event.target;
    if (target.getAttribute('href').charAt(0) === '#') {
      return event.preventDefault();
    }
  });

  function removeEventsFromCurrentPage() {
    if (R.currentPage && R.currentPage.removeEvents) {
      R.currentPage.removeEvents();
    }

    $document.off(R.touchEvent, ".animate-scroll");
  }

  function requiredToStart() {
    var scrollTimer = 0;

    if (!R.isTurbo) {
      window.localStorage.recognizeweburl = window.location.pathname;

      rLog('Start of checkIfScrolledToHashLink');
      checkIfScrolledToHashLink();

      $document.on(R.touchEvent, "a[data-event], button[data-event]", trackEvent);
      $document.on("submit", 'form[data-event]', trackEvent);
      $document.on("blur", "a[data-ycbm-modal]", trackEvent);

      $document
      .on("turbolinks:before-cache", function() { // Current page is about to be saved to cache.
        removeEventsFromCurrentPage();

        restoreTooltipTitles();
        destroySelect2Elements();
        closeSwalIfOpen();

        R.ui.header.removeEvents();
        window.R.ui.drawer.close();
        removeTooltips();
      })
      .on("turbolinks:request-start", function() { // A new page is about to be fetched from the server.
        $html.addClass("loading");
        R.isTurbo = true;
        $document.off("recognize:init");
        removeTooltips();
      })
      .on("turbolinks:request-end", function() { // A page has been fetched from the server, but not yet parsed.
        window.localStorage.recognizeweburl = window.location.href;
        $html.removeClass("loading");

        if (window.balanceText) {
          setTimeout(function() {
            balanceText(".balance-text");
          }, 500);
        }

        removeTooltips();
      })
      .on("turbolinks:before-render", function() { // Page has been fetched (local / remote) and is about to be rendered
        // this is needed for both page visits and restores
        window.R.ready = false;
      });

      // This is to fix the Turbolinks Issue where the back button doesn't work when returning to anchored paths.
      // https://github.com/turbolinks/turbolinks/pull/285
      // and https://github.com/Recognize/recognize/issues/1208
      window.addEventListener('popstate', popStateTurbolinksHashFix, false);

      $document.on(R.touchEvent, "a", function() {
        var $this = $(this);
        if (this.href.indexOf("#") > -1) {
          window.R.hasClickedHashLink = true;
        }
      });

    }

    function popStateTurbolinksHashFix(event) {
      var href = window.location.href;
      // The popstate event is fired each time when the current history entry changes.

      // If the incoming page, already window.location.href in this situation funny enough, is different from the last page (localStorage.recognizeweburl) AND has a # in the URL, then we have to reload the page to make this work I'm afraid
      // Also this bug only occurs when someone clicks a hash link, not when the page loads and has a hash link.
      if ( (window.location.pathname.indexOf(window.localStorage.recognizeweburl) == -1) && (href.indexOf("#") > -1) && window.R.hasClickedHashLink) {
        window.removeEventListener('popstate', popStateTurbolinksHashFix);
        window.R.hasClickedHashLink = undefined;
        Turbolinks.visit(href);
      }
    }

    if ( R.pages && R.pages[dataScript] ) {
      R.currentPage = new R.pages[dataScript]();
    } else if(dataScript.match(/^company_admin/)) {
      R.currentPage = new R.CompanyAdmin();
    }

    if(window.R.ui.remoteCheckboxToggle) {
      window.R.ui.remoteCheckboxToggle();
    }

    setTimeout(function() {
      $body.addClass("ready");
    }, 1000);

    if ($('.lazy').Lazy) {
      $('.lazy').Lazy({
        // your configuration goes here
        scrollDirection: 'vertical',
        effect: 'fadeIn',
        visibleOnly: true,
        onError: function(element) {
          console.log('error loading ' + element.data('src'));
        }
      });
    }

    if ( $("body.logout").length ) {
        $window.on("scroll.once", function() {
            if ($window.scrollTop() > 50) {
                $(document.body).addClass("scrolled");
                $window.off("scroll.once");
            } else {
                $(document.body).removeClass("scrolled");
            }
        });

        $window.scroll(function() {
            clearTimeout(scrollTimer);
            scrollTimer = setTimeout(function() {
                if ($window.scrollTop() > 50) {
                    $(document.body).addClass("scrolled");
                } else {
                    $(document.body).removeClass("scrolled");
                }
            }, 250);
        });
    }

  }

  if (!window.R.ui.header) {
    R.ui.header = new R.ui.Header();
  } else {
    R.ui.header.addEvents();
  }

  function trackEvent(e) {
    var $this = $(e.target);
    var data = {};

    var category = $this.data('category') || $body.attr("id");
    var event = $this.data('event');
    var value = $this.data('value');

    if (category) data.category = category;
    if (event) data.event = event;
    if (value) data.value = value;

    if(window.analytics) {
      window.analytics.track(event, data);
    }
  }

  if (!window.R.ajaxify) {
    window.R.ajaxify = new window.R.Ajaxify();
  }

  setTimeout(function() {
    $(".animate-hidden").removeClass("animate-hidden");
    if (window.balanceText) {
      balanceText(".balance-text");
    }
  }, 500);

  function checkIfScrolledToHashLink() {

    var href = window.location.href;

    if (href.indexOf("#") > -1) {
      setTimeout(function() {

        var el = href.substring(href.indexOf("#"), href.length),
          $el, offsetTop;

        if (el.indexOf("?") > -1) {
          el = el.subString(0, el.indexOf("?"));
        }

        $el = $(el);

        if (!$el.length === 0) {
          return;
        }

        offsetTop = $el.offset().top;

        if (offsetTop - $window.scrollTop() > 300) {
          $('html, body').animate({
            scrollTop: offsetTop
          }, 800);
        }
      }, 2000);

    }

  }

  function initTooltips() {
    if (!hasTouch && $.fn.tooltip) {
      $("[title]").tooltip({
        placement: "bottom",
        delay: 500
      });
    }
  }

  function removeTooltips() {
    $(".tooltip").remove();
    setTimeout(function() {
        $(".tooltip").remove();
    }, 500);
  }

  /**
   * The title attribute is used to initTooltips(), but it is removed with the call to bootstrap's tooltip() method
   * This function adds it back so that it works again on page restore
   */
  function restoreTooltipTitles() {
    $("[data-original-title]").each(function() {
      var $this = $(this);
      $this.attr("title", $this.data("original-title"));
    });
  }

  function initCaptcha() {
      /**
       * This init is skipped for the majority of specs involving captcha forms, which have Recaptcha disabled.
       * This prevents unnecessary 3p requests.
       */

      if ($(".captcha-trigger-button").length && !gon.skip_captcha) {
          new window.R.Captcha();
      }
  }
  /**
   * Destroy current select2 container/data before Turbolinks caches the page
   * so that it doesn't add up every time when this page is restored (where it won't work either)
   */
  function destroySelect2Elements() {
    $('.select2-hidden-accessible').each(function() {
      var $elem = $(this);
      if ($elem.data('select2'))
        $elem.select2('destroy');
    });
  }

  /**
   * Close any open swal when exiting the page
   * because all js components inside swal are broken on page restore, including the swal buttons
   */
  function closeSwalIfOpen() {
    if (typeof Swal === 'undefined' || !Swal.isVisible()) return;

    // Disable animation, as it causes the swal removal code to be wrapped in an async callback that is never executed
    // (this is only needed outside company-admin)
    $(Swal.getPopup()).addClass('swal2-noanimation');

    Swal.close();
  }

  window.R.ready = true;
};


$(document).on("turbolinks:load", ready);

// marketing now has async javascript (in production env only)
// Turbolinks load event doesn't fire with deferred scripts
// so we also need to add standard window load event.
if($('html.marketing').length) {
  window.addEventListener("load", ready);
}

function ready() {
  try {
    window.R.init();
  } catch(e) {
    console.log("Recognize didn't load :(");
    console.log(e.stack);
  }
}
