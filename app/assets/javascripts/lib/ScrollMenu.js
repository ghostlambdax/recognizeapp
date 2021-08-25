(function() {
  window.R = window.R || {};
  window.R.ScrollMenu = ScrollMenu;

  var cssTopOfMenu = 80;

  function ScrollMenu(menu, navItem, container, callback) {
    if (!menu) { menu = "#article-menu"; }
    this.$content = $(navItem);
    this.$menu = $(menu);
    this.$container = $(container);
    this.setupVariables(function() {
      this.setNavPosition();
      this.setNavHighlighting();
      this.addEvents();
      if (callback) {callback();}
    }.bind(this));

  }

  ScrollMenu.prototype.setupVariables = function(callback) {
    var that = this;
    var $images = $("img");
    var imagesToLoad = [];
    var interval;
    var defaultMenuPos;
    var toggleCssClasses = "top0";

    this.$menu.addClass(toggleCssClasses);
    this.$menu.removeClass('fixed');

    // Image management
    if ($images.length) {

      $images.each(function() {
        // image not loaded?
        if (!this.complete) {
          imagesToLoad.push(this);
        }
      });

      if (imagesToLoad.length) {
        $images.load(function() {
          defaultMenuPos = parseInt(this.$menu.offset().top.valueOf());
        }.bind(this));
      } else {
        defaultMenuPos = parseInt(this.$menu.offset().top.valueOf());
      }
    }

    interval = setInterval(function() {
      if (defaultMenuPos !== undefined) {
        clearInterval(interval);

        // To make a copy of the menuPosition so it doesn't change when the $menu.offset().top changes.
        $.extend(this, {defaultMenuPosition: defaultMenuPos});
        this.$menu.removeClass(toggleCssClasses);
        callback();

      } else {
        defaultMenuPos = parseInt(this.$menu.offset().top.valueOf());
      }
    }.bind(this), 200);

    this.menuHeight = this.$menu.height();

    this.menuBottomPx = cssTopOfMenu + this.menuHeight;

  };

  ScrollMenu.prototype.setNavHighlighting = function() {
    var that = this;
    if (!this.$menu) {return;}

    var scrollTop = $window.scrollTop();

    this.$content.each(function(i) {
      var $this = $(this);
      var offsetTop = $this.offset().top;
      var $nextItem = that.$content.eq(i+1);
      var nextItemTop = $nextItem.length ? $nextItem.offset().top : 1000;

      if (offsetTop <= (scrollTop+200) && scrollTop < (nextItemTop+200)) {
        that.$menu.find("a").removeClass("active");
        that.$menu.find("a[href='#"+this.id+"']").addClass("active");
      }
    });
  };

  ScrollMenu.prototype.setNavPosition = function() {
    if (!this.$menu) {return;}

    var $container = this.$container;
    var scrollTop = $window.scrollTop();
    var bottomOfArticle = parseInt($container.offset().top) + $container.height();
    var scrollPositionOfBottomMenu = scrollTop + this.menuBottomPx;

    rLog('scrollTop', scrollTop);
    rLog('bottomOfArticle', bottomOfArticle);
    rLog('scrollPositionOfBottomMenu', scrollPositionOfBottomMenu);
    rLog('defaultMenuPosition', this.defaultMenuPosition);


    // If user has scrolled enough to fix it from the top.
    // And
    // Bottom position of menu is not going beyond the article
    // Then fix it to the side

    if (this.defaultMenuPosition < scrollTop && scrollPositionOfBottomMenu < bottomOfArticle) {
      rLog('setNavPosition', 'NavFixed');
        this.$menu.attr('style', '');
        this.$menu.css({
          top: cssTopOfMenu + 'px'
        }).addClass('fixed');

      // If bottom of menu is greater than bottom of article
      // Then make the menu absolute
      //
    } else if (scrollPositionOfBottomMenu >= bottomOfArticle) {
      rLog('setNavPosition', 'Bottom absolute');
      this.$menu.attr('style', '');
      this.$menu.css({
        top: (bottomOfArticle-this.menuHeight) + 'px',
        position: 'absolute'
      }).removeClass('fixed');

      // Top of article
    } else if (this.defaultMenuPosition >= scrollTop) {
      rLog('setNavPosition', 'top of article');
      this.$menu.attr('style', '');
      this.$menu.css({
        top: '0px'
      }).removeClass('fixed');
    }

    rLog('ScrollMenu ---------');
  };

  ScrollMenu.prototype.addEvents = function() {
    var highlightTimer;
    var positionTimer;
    var that = this;

    if (this.$menu.length) {
      $window.on('scroll.article', function() {
        highlightTimer = setTimeout(function() {
          clearTimeout(highlightTimer);
          that.setNavPosition();
          that.setNavHighlighting();
        }, 200);
      });
    }

    $document.on('animate-scroll', this.setNavHighlighting.bind(this));
    $document.one("turbolinks:request-start", this.removeEvents.bind(this));
  };

  ScrollMenu.prototype.removeEvents = function() {
    $window.off('scroll.article');
    $document.off('animate-scroll', this.setNavHighlighting.bind(this));
  };
})();