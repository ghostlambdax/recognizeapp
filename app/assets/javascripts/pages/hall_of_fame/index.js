window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["hall_of_fame-index"] = (function() {

  var H = function() {
    this.scrollingElement = ".time-periods-wrapper";

    this.addEvents();
  };

  H.prototype.checkAllArrows = function() {
    var that = this;
    $(this.scrollingElement).each(function() {
      that.checkArrows(this);
    });
  };

  H.prototype.scrollRow = function($scrolling, $trigger) {
    var pageWidth = $(window).width();

    $scrolling.animate({
      scrollLeft: ( $trigger.hasClass("arrow-clip-right") ? $scrolling.scrollLeft() + pageWidth : $scrolling.scrollLeft() - pageWidth )
    });
  };

  H.prototype.addEvents = function() {
    var that = this;
    var timer = 0;

    $(document).on(R.touchEvent, ".arrow-clip", function(e) {
      var $this = $(this);
      var $scrolling = $this.closest(that.scrollingElement);

      e.preventDefault();

      if ($scrolling.data().rightEnd === 'true') {
        that.moreResultsAjax(this, function() {
          that.scrollRow($scrolling, $this);
        });
      } else {
        that.scrollRow($scrolling, $this);
      }

    });

    $(this.scrollingElement).on("scroll", function() {
      var el = this;
      clearTimeout(timer);
      timer = setTimeout(function() {
        that.checkArrows(el);
      }, 30);
    });

    new window.R.Select2(bindSelect2);
    this.pagelet = new window.R.Pagelet(function(el) {
      if ($(el).closest(this.scrollingElement).length) {
        this.checkArrows($(el).closest(this.scrollingElement));
      }
    }.bind(this));
  };

  H.prototype.moreResultsAjax = function(el, callback) {
      var $el = $(el);
      var $parent = $el.closest(".time-periods-wrapper");
      var endpoint;

      $el = $parent.find('.see-more-button:last');

      // If no load more button just hide it and stop.
      if (!$el.length || $parent.hasClass('loading')) {
        return $($el.context).addClass('hidden');
      } else {
        $parent.addClass('loading');
        endpoint = $el.data().endpoint;
      }

      // If there is a load more button there is mor to load.
      $.get(endpoint, function(data) {
        var $seeMoreButton;
        $parent.find(".see-more-wrapper").remove(); // remove old see more li
        $parent.find('.pagelet').append(data);
        $parent.removeClass('loading');
        
        // get next button
        $seeMoreButton = $parent.find(".see-more-wrapper .see-more-button");

        // if there isn't a button, there is no more to load
        // so hide the arrow
        if (!$seeMoreButton.length) {
          return $($el.context).addClass('hidden');
        }

        if ( callback && (typeof callback === "function") ) { callback(); }
      });
  };

  H.prototype.checkArrows = function(el) {
    var $el = $(el);
    var actualScrollWidth = el.scrollWidth + (el.offsetWidth - el.clientWidth)
    var scrolledAmount = actualScrollWidth - $(document).width() - el.scrollLeft;

    if ($el.find(".time-period:last-child").length && $el.find(".time-period:last-child").offset().left + $(el).scrollLeft() + 150 <= $(window).width() ) {
      return $el.find(".arrow-clip, .arrow-clip-left").addClass("hidden");
    }

    $el.data().rightEnd = scrolledAmount < 10 ? 'true' : 'false';

    if (el.scrollLeft > 10 ) {
      $el.find(".arrow-clip-left").removeClass("hidden");
    } else {
      $el.find(".arrow-clip-left").addClass("hidden");
    }

    if($el.data().rightEnd === 'false') {
      $el.find(".arrow-clip-right").removeClass("hidden");
    } else {
      $el.find(".arrow-clip-right").removeClass("hidden");
    }
  };

  H.prototype.removeEvents = function() {
    $('.param-select').off('select2:select');
  }

  function bindSelect2() {
    var $selects = $('.param-select').select2();
    $selects.on('select2:select', function(e){
      var $this = $(this),
          queryObj;

      if($this.data('reset-tools')) {
        queryObj = {};
        queryObj[$this.prop('name')] = $this.val();

        // also manually carry over viewer
        var viewer = window.R.utils.queryParams()['viewer']
        if(viewer) {
          queryObj['viewer'] = viewer;
        }

      } else {
        queryObj = window.R.utils.queryParams();
        queryObj[$this.prop('name')] = $this.val();
      }

      Turbolinks.visit(window.location.pathname+"?"+$.param(queryObj));

    });
  }

  return H;

})();
