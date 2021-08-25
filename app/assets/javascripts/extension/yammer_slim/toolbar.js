(function() {
  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.toolbar = {
    create: create
  };

  var new_yammer_html_toolbar = '<script id="r-new_yammer_html_toolbar" type="text/x-handlebars-template"><div id="recognize-list" class="sidebarNavLink"><div class="y-block navigationItem"><a id="yammer-2020-recognize-link" href="{{signupUrl}}" class="navigationItem"><div class="y-block block-p"><div class="fixedGridRow"><div class="y-fixedGridColumn iconColumn">' +
      '<i aria-hidden="true" class="r-icon">★</i>' +
      '</div>' +
      '<div class="y-fixedGridColumn fixedGridColumn"><div class="verticalAlign">' +
      '<div class="inner-86">' +
      '<div class="" dir="auto" title="{{i18n.recognize}}">' +
      '<div class="block-14font">{{i18n.recognize}}</div>' +
      '</div>' +
      '</div>' +
      '</div>' +
      '</div></div></div></a></div></div>';

  var html = '<style>#recognize-list a:hover {text-decoration: none;}</style>' +
      '<script id="r-recognitions-toolbar" type="text/x-handlebars-template">' +
      '<li id="recognize-toolbar" class="yj-header-menu-item  yj-header-navigation--jewel yj-header-list-section-border sprite-parent yj-component" data-yj-tabname="recognition">\n' +
      '      <a href="javascript://" title="Recognitions" role="button" aria-haspopup="true" class="yj-header-navigation--jewel-link yj-simple-click-menu-trigger" style="position: static;">\n' +
      '        <span class="yj-header-navigation--jewel-text">&#9733; {{i18n.recognize}}</span>\n' +
      '      </a>\n' +
      '      <ul class="yj-header-navigation--dropdown-left yj-click-menu">\n' +
                '<li class="yj-header-navigation--dropdown-item" role="presentation">\n' +
      '          <a id="stream" href="//recognizeapp.com?viewer=yammer" class="yj-header-navigation--dropdown-link" title="{{i18n.stream}}" role="menuitem" aria-label="Visit main page of Recognize">{{i18n.stream}}</a>\n' +
      '        </li>\n' +
      '        <li class="yj-header-navigation--dropdown-item" role="presentation">\n' +
      '          <a id="recognize-someone-trigger" href="//recognizeapp.com/recognitions/new_chromeless?viewer=yammer" class="yj-header-navigation--dropdown-link" title="{{i18n.send_recognition}}" role="menuitem" aria-label="send recognition">{{i18n.send_recognition}}</a>\n' +
      '        </li>\n'+

            '<li class="yj-header-navigation--dropdown-item" role="presentation">\n' +
  '          <a href="{{signupUrl}}" class="yj-header-navigation--dropdown-link" title="Connect Recognize" role="menuitem" aria-label="send recognition">{{i18n.reconnect}}</a>\n' +
  '        </li>\n'+
      '      </ul>\n' +
      '    </li></script>' +
      '<script id="r-recognitions-toolbar-new-main" type="text/x-handlebars-template">\n' +
      '    <li id="recognize-list" class="switcher-option" data-name="Recognize">\n' +
      '      <a class="unstyle-button-as-span yj-simple-click-menu-trigger" href="javascript://">\n' +
      '        <span class="option-icon yamicon">★</span>\n' +
      '        <span class="option-label">{{i18n.recognize}}</span>\n' +
      '      </a>\n' +
      '\n' +
      '      <ul class="yj-click-menu yj-nav-menu--primary-actions-drop-down-list" style="display: none;">\n' +
      '\n' +

             '<li class="yj-nav-menu--primary-actions-drop-down-item" role="presentation">\n' +
      '          <a  id="stream" href="//recognizeapp.com?viewer=yammer" class="yj-nav-menu--primary-actions-drop-link" data-qaid="ellipsis_menu_invite_link" role="menuitem">\n' +
      '            <strong>{{i18n.stream}}</strong>\n' +
      '          </a>\n' +
      '        </li>\n' +
      '        <li class="yj-nav-menu--primary-actions-drop-down-item" role="presentation">\n' +
      '          <a  id="recognize-someone-trigger" href="//recognizeapp.com/recognitions/new_chromeless?viewer=yammer" class="yj-nav-menu--primary-actions-drop-link" data-qaid="ellipsis_menu_invite_link" role="menuitem">\n' +
      '            <strong>{{i18n.send_recognition}}</strong>\n' +
      '          </a>\n' +
      '        </li>\n' +

               '<li class="yj-nav-menu--primary-actions-drop-down-item" role="presentation">\n' +
      '          <a href="{{signupUrl}}"  class="yj-nav-menu--primary-actions-drop-link" data-qaid="ellipsis_menu_invite_link" role="menuitem">' +
                  '<strong>{{i18n.reconnect}}</strong>' +
      '         </a>\n' +
      '        </li>\n'+
      '      </ul>\n' +
      '    </li>\n' +
      '</script>' +
      '<script id="r-recognitions-toolbar-sidebar" type="text/x-handlebars-template">\n' +
      '\n' +
      '  <li id="recognize-list-sidebar" class="yj-header-menu-item yj-nav-menu--primary-actions-item yj-nav-menu--primary-actions-notifications">\n' +
      '    <a href="javascript://" class="yj-nav-menu--primary-actions-link link yj-notifications-menu yj-simple-click-menu-trigger yj-meta-dropdown"  aria-haspopup="true" role="button" data-speechtip="" style="position: relative;">\n' +
      '      <span class="r-icon">R</span>\n' +
      '    </a>\n' +
      '    <ul class="yj-click-menu yj-nav-menu--primary-actions-drop-down-list" style="display: none;">\n' +
      '\n' +
      '<li class="yj-nav-menu--primary-actions-drop-down-item" role="presentation">\n' +
      '          <a id="stream" href="//recognizeapp.com?viewer=yammer" class="yj-nav-menu--primary-actions-drop-link" data-qaid="ellipsis_menu_invite_link" aria-label="Visit main page of Recognize">{{i18n.stream}}</a>\n' +
      '        </li>\n' +
      '      <li class="yj-nav-menu--primary-actions-drop-down-item" role="presentation">\n' +
      '        <a  id="recognize-someone-trigger" href="//recognizeapp.com/recognitions/new_chromeless?viewer=yammer" class="yj-nav-menu--primary-actions-drop-link" data-qaid="ellipsis_menu_invite_link" role="menuitem">\n' +
      '          <strong>{{i18n.send_recognition}}</strong>\n' +
      '        </a>\n' +
      '      </li>\n' +

           '<li class="yj-nav-menu--primary-actions-drop-down-item" role="presentation">\n' +
      '          <a href="{{signupUrl}}"  class="yj-nav-menu--primary-actions-drop-link" data-qaid="ellipsis_menu_invite_link" role="menuitem">' +
      '<strong>{{i18n.reconnect}}</strong>' +
      '         </a>\n' +
      ' \n' +
      '    </ul>\n' +
      '  </li>\n' +
      '\n' +
      '</script>';

  var $toolbar,
      templateSidebar,
      templateTopbar,
      languageSet,
      templateSidebarNew2020,
      templateNewMain;

  var isNewYammer = function() {
    return !!document.getElementById('root');
  };

  window.$body = window.$body || jQuery(document.body);

  function create(isLoggedIn, callback) {
    languageSet = Recognize.patterns.i18n();

    if ((!templateSidebar || !templateTopbar) && !templateSidebarNew2020) {
      if (!jQuery("#r-recognitions-toolbar").length || !jQuery("#r-recognitions-toolbar-new").length) {

        if (isNewYammer()) {
          styles2020();
          $body.append( new_yammer_html_toolbar );
          templateSidebarNew2020 = Handlebars.compile( jQuery("#r-new_yammer_html_toolbar").html() );

          attachNewToolbar(isLoggedIn);

        } else {
          $body.append( html );
          templateTopbar = Handlebars.compile( jQuery("#r-recognitions-toolbar").html() );
          templateNewMain = Handlebars.compile( jQuery("#r-recognitions-toolbar-new-main").html() );

          attachToolbar(isLoggedIn);

        }


      }

    }

    function attachNewToolbar() {
      var $sidebar = jQuery('[class*=leftSidebarColumn] [class*=mainSection]');
      var template = templateSidebarNew2020;

      if (jQuery("#recognize-list").length > 0) {
        jQuery("#recognize-list").remove();
      }

      $sidebar.append(template({
        i18n: languageSet,
        signupUrl: Recognize.host+'/auth/yammer?viewer=yammer'
      }));
    }

    function attachToolbar() {
      var template;
      var $mainColumnToolbar = jQuery("#column-two .yj-global-publisher-switcher");
      var $sideColumnToolbar = jQuery("#column-one #notifications-jewel").parent();
      var statsURLParameters = "";

      template = templateNewMain;
      $toolbar = $mainColumnToolbar;

      if (jQuery("#recognize-list").length > 0) {
        jQuery("#recognize-list").remove();
      }

      $toolbar.append(template({
        i18n: languageSet,
        statsURLParameters: statsURLParameters,
        signupUrl: Recognize.host+'/auth/yammer?viewer=yammer'
      }));

      if (jQuery("#recognize-list-sidebar").length > 0) {
        jQuery("#recognize-list-sidebar").remove();
      }

      template = Handlebars.compile( jQuery("#r-recognitions-toolbar-sidebar").html() );

      $sideColumnToolbar.append(template({
        signupUrl: Recognize.host+'/auth/yammer?viewer=yammer',
        i18n: languageSet
      }));

    }

    window.$body.off("click.recognize");


    window.$body.on("click.recognize", "#yammer-2020-recognize-link", function(e) {
      e.preventDefault();
      Recognize.utils.openWindow(Recognize.path("auth/yammer?viewer=yammer&redirect=/redirect/recognitions/new"));
    });

    window.$body.on("click.recognize", "#stream", function(e) {
      e.preventDefault();
      Recognize.utils.openWindow(Recognize.path("auth/yammer?viewer=yammer"));
    });

    window.$body.on("click.recognize", "#recognize-someone-trigger", function(e) {
      e.preventDefault();
      Recognize.patterns.recognitionForm.open();
    });

    window.$body.on("click.recognize", "#reports-trigger", function(e) {
      var params = "";
      e.preventDefault();

      if ($(this).attr("href").indexOf("#yammer") > -1) {
        params = "#yammer";
      }
      openIframe(languageSet.stats, Recognize.path("reports/"+params));
    });

    window.$body.on("click.recognize", "#profile-trigger", function(e) {
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

  function styles2020() {
    var styles = "<style>.navigationItem {\n" +
        "  display: block;\n" +
        "  margin-top: 0px;\n" +
        "  margin-right: 0px;\n" +
        "  margin-bottom: 0px;\n" +
        "  margin-left: 0px;\n" +
        "  padding-top: 0px;\n" +
        "  padding-right: 0px;\n" +
        "  padding-bottom: 0px;\n" +
        "  padding-left: 0px;\n" +
        "  text-align: inherit;\n" +
        "  color: rgb(97, 97, 97);\n" +
        "  cursor: pointer;\n" +
        "  border-width: initial;\n" +
        "  border-style: none;\n" +
        "  border-color: initial;\n" +
        "  border-image: initial;\n" +
        "  background: none;\n" +
        "  font: inherit;\n" +
        "  overflow: visible;\n" +
        "  text-decoration: none;\n" +
        "  outline: none;\n" +
        "}\n" +
        ".fixedGridRow {\n" +
        "  display: flex;\n" +
        "}\n" +
        "\n" +
        ".iconColumn {\n" +
        "  flex-grow: 0;\n" +
        "  flex-shrink: 0;\n" +
        "  flex-basis: 32px;\n" +
        "  min-width: auto;\n" +
        "  line-height: 20px;\n" +
        "  font-size: 14px;\n" +
        "  display: flex;\n" +
        "  flex-direction: column;\n" +
        "  align-items: flex-start;\n" +
        "  justify-content: flex-start;\n" +
        "  color: rgb(0, 0, 0);\n" +
        "}\n" +
        "\n" +
        ".sidebarNavLink {\n" +
        "  position: relative;\n" +
        "}\n" +
        "\n" +
        ".fixedGridRow > .y-fixedGridColumn:first-child {\n" +
        "  margin-left: 0px;\n" +
        "}\n" +
        "\n" +
        ".fixedGridColumn {\n" +
        "  flex-grow: 1;\n" +
        "  flex-shrink: 1;\n" +
        "  flex-basis: auto;\n" +
        "  min-width: 1px;\n" +
        "}\n" +
        "\n" +
        ".verticalAlign {\n" +
        "  display: flex;\n" +
        "  flex-direction: column;\n" +
        "  justify-content: center;\n" +
        "  align-items: flex-start;\n" +
        "  text-align: left;\n" +
        "  height: 100%;\n" +
        "}\n" +
        ".block-p {\n" +
        "    padding-top: 8px;\n" +
        "    padding-bottom: 8px;\n" +
        "    padding-left: 8px;\n" +
        "    padding-right: 8px;\n" +
        "}" +
        ".r-icon {" +
        "font-style: normal; color: rgb(97, 97, 97);}" +
        ".block-14font {\n" +
        "    font-size: 14px;\n" +
        "    line-height: 20px;\n" +
        "}</style>";

      jQuery(document.body).append(styles);
  }

})();


