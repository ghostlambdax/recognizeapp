(function() {
  var HIDDEN_CLASS = "visibility-hidden", CLASS = "header-menu-open";
  var scrollPosition = 0;
  var bgColor = $body.css("background-color");
  window.R = window.R || {};
  window.R.ui = window.R.ui || {};
  R.ui.Header = Header;

  var searchTimer = 0, searchOpenTimer = 0;

  function Header() {
    this.sharedLoadItems();
    this.menuTimer = 0;
    this.recognitionFormID = "#recognition-new-wrapper";
    this.addEvents();
    this.idp = new window.R.IdpRedirecter();
    this.idp.addEventsForAuthFields();
  }

  function initAutoComplete() {
    if ($("#header-search-input").length === 0) {
      return;
    }

    this.autocomplete = new window.Autocomplete({
      input: "#header-search-input",
      appendTo: "#header-search-results",
      success:function(data) {
        var str = {}
        str["email"] = data.email || "";

        if(data.web_url) { // presence of web_url means we have data from yammer
          str["yammer_id"] = data.id || "";
        }

        str["type"] = data.type || "";
        str["name"] = data.name || "";

        var url = "/goto";
        if(location.search.match(/^\?/)) {
          url = url + location.search + "&"+ $.param(str);
        } else {
          url = url + "?" + $.param(str);
        }
        Turbolinks.visit(url);
      }
    });
  }

  Header.prototype.sharedLoadItems = function() {
    if (window.Autocomplete) {
      initAutoComplete();
    }
    this.$menu = $(".header-menu");

    if (Modernizr.ios) {
      $(".ios header.ios-hidden").removeClass("ios-hidden");
    }
  };

  function showPage() {
    if ( this.hasAttribute("id") === "login-menu" || $window.width() > 768) {
      return;
    }

    $window.scrollTop(scrollPosition);
    $body.removeClass("menuOpen");
  }

  Header.prototype.addEvents = function() {
    var that = this;
    var $header = $("#header");
    this.sharedLoadItems();
    if(this.idp) {
      this.idp.addEventsForAuthFields();
    }

    $("#navbar .dropdown").on("hidden.bs.dropdown", showPage);
    $("#bs-example-navbar-collapse-1").on("hide.bs.collapse", showPage);

    $("#navbar .dropdown").on("shown.bs.dropdown", function(event) {
      var target = $(event.target);

      if ( target.prop('id') === 'login-menu' ) {
        // Select login field when login-menu dropdown occurs.
        target.find('.user-session-email').select();
      }

      if ($window.width() <= 768) {
        var $navbarCollapse = $(this).closest(".navbar-collapse");
        if ($navbarCollapse.length === 0 || $("body.menuOpen").length > 0) {
          return;
        }

        $body.addClass("menuOpen");

        scrollPosition = $window.scrollTop();
      }
    });

    $document.on("mouseover", "#header-users, #search-popup, #search-popup .ui-autocomplete", function(e) {
      e.preventDefault();
      clearTimeout(searchTimer);
      searchOpenTimer = setTimeout(function() {
        $("#search-popup").removeClass("visibility-hidden");
      }, 500);

    });

    $document.on("mouseout", "#header-users, #search-popup", function(e) {
      e.preventDefault();
      clearTimeout(searchOpenTimer);
      searchTimer = setTimeout(function() {
        $("#search-popup").addClass("visibility-hidden");
      }, 500);

    });

    $window.keyup(function(e) {
      if (e.keyCode === 27 && $body.hasClass(CLASS)) {
        that.closeMenu();
      }
    }.bind(this));

    $body.on(R.touchEvent, "#header-settings", function(e) {
      e.preventDefault();

      if ($body.hasClass(CLASS)) {
        that.closeMenu();
      } else {
        clearTimeout(that.menuTimer);
        $body.addClass(CLASS);
        that.$menu.removeClass(HIDDEN_CLASS);
        window.R.ui.drawer.close();
      }
    });

    Header.prototype.removeEvents = function() {
      $body.off(R.touchEvent,"#header-settings");
      $window.unbind("keyup");
      $document
        .off("mouseout")
        .off("mouseover")
        .off(R.touchEvent, ".recognize-new");
      if(this.idp) {
        this.idp.removeEvents();
      }
    };

    Header.prototype.closeMenu = function() {
      var that = this;
      $body.removeClass(CLASS);
      this.menuTimer = setTimeout(function() {
        that.$menu.addClass(HIDDEN_CLASS);
      }, 500);
    };
  };
})();
