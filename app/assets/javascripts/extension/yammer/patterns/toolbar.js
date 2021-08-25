(function() {
  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.toolbar = {
    create: create
  };

  var $toolbar,
      templateSidebar,
      templateTopbar,
      languageSet;

  window.$body = window.$body || jQuery(document.body);

  function create(isLoggedIn, callback) {
    languageSet = Recognize.patterns.i18n();

    if (isLoggedIn === "false") {
      isLoggedIn = false;
    }

    if (!templateSidebar || !templateTopbar) {
      Recognize.ajax({
        url: Recognize.file.getPath("templates/toolbar.html"),
        success: function(html) {

          if (!jQuery("#r-recognitions-toolbar").length) {
            $body.append( html );

            templateTopbar = Handlebars.compile( jQuery("#r-recognitions-toolbar").html() );
            templateNewMain = Handlebars.compile( jQuery("#r-recognitions-toolbar-new-main").html() );
          }

          attachToolbar(isLoggedIn);

        }.bind(this)
      });
    } else {
      attachToolbar(isLoggedIn);
    }

    function attachToolbar(isLoggedIn) {
      var template;
      var $mainColumnToolbar = jQuery("#column-two .yj-global-publisher-switcher");
      var $sideColumnToolbar = jQuery("#column-one #notifications-jewel").parent();
      var statsURLParameters = "";

      template = templateNewMain;
      $toolbar = $mainColumnToolbar;

      if (Recognize.currentUser) {
        if (Recognize.currentUser.company_admin === "false") {
          Recognize.currentUser.company_admin = false;
        }

        if (Recognize.currentUser.allow_stats === "false") {
          Recognize.currentUser.allow_stats = false;
        }

        if (Recognize.currentUser.allow_yammer_stats === "true" || Recognize.currentUser.allow_yammer_stats === true) {
          Recognize.currentUser.allow_stats = true;
          statsURLParameters = "#yammer";
        }
      }

      if (jQuery("#recognize-list").length > 0) {
        jQuery("#recognize-list").remove();
      }

      $toolbar.append(template({
        user: Recognize.currentUser,
        loggedIn: isLoggedIn,
        signupUrl: Recognize.host+'/signup/yammer?redirect='+window.location.href,
        i18n: languageSet,
        statsURLParameters: statsURLParameters
      }));

      if (jQuery("#recognize-list-sidebar").length > 0) {
        jQuery("#recognize-list-sidebar").remove();
      }

      template = Handlebars.compile( jQuery("#r-recognitions-toolbar-sidebar").html() );

      $sideColumnToolbar.append(template({
        user: Recognize.currentUser,
        loggedIn: isLoggedIn,
        signupUrl: Recognize.host+'/signup/yammer?redirect='+window.location.href,
        i18n: languageSet
      }));

    }

    window.$body.on("click", "#recognize-someone-trigger", function(e) {
      e.preventDefault();
      Recognize.patterns.recognitionForm.open();
    });

    window.$body.on("click", "#company-admin-trigger", function(e) {
      e.preventDefault();
      openIframe(languageSet.company_admin, Recognize.path("company/dashboard"));
    });

    window.$body.on("click", "#reports-trigger", function(e) {
      var params = "";
      e.preventDefault();

      if ($(this).attr("href").indexOf("#yammer") > -1) {
        params = "#yammer";
      }
      openIframe(languageSet.stats, Recognize.path("reports/"+params));
    });

    window.$body.on("click", "#profile-trigger", function(e) {
      var $this = jQuery(this);
      e.preventDefault();
      openIframe(languageSet.profile, $this.attr("href"));
    });


  }

  function openIframe(title, url) {
    var iframeHTML, gettingModalUrl, template;

    template = Handlebars.compile(jQuery('#r-iframe').html());

    iframeHTML = template({
      url: url+"?viewer=yammer",
      id: 'r-stats-iframe',
      height: $(window).height() - 100+"px"
    });

    Recognize.patterns.overlay.open(title, iframeHTML, "full");
  }

})();
