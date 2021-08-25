window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["home-index"] = (function($, window, undefined) {
  var hoverTimer;
  var valueText;
  var useType;

  function FadeCarousel() {
    this.items = $(".fade-carousel");
    this.timer = [];
    this.index = 0;
  }

  FadeCarousel.prototype.start = function(index) {
    var $item = this.items.eq(index);
    var that = this;

    clearInterval(this.timer[this.index]);
    this.itemChildIndex = 1;
    this.index = index;

    this.timer[index] = setInterval(function() {
      var $children = $item.children();
      $item.find(".show").removeClass("show");
      $children.eq(that.itemChildIndex).addClass("show");

      if ((that.itemChildIndex+1) === $children.length) {
        that.itemChildIndex = 0;
      } else {
        that.itemChildIndex++;
      }

    }, 2000);
  };

  /*
  *
  * Constructor
  *
  *
  * */
  var H = function() {
    this.addEvents();
  };

  H.prototype.hoverIntegrations = function(el) {
    var $extraInfo = $(this).next();
    var title = $extraInfo.hasClass("extra-info") ? $extraInfo.html() : $(this).attr("alt");
    var $this = $(this);
    var $parent = $this.closest(".hover-wrapper");
    var $content = $parent.find(".content");

    clearTimeout(hoverTimer);

    $parent.find(".hover-content-target").html(title);

    $content.addClass("show-content");
  };

  H.prototype.hoverIntegrationsOff = function() {
    var $this = $(this);
    hoverTimer = setTimeout(function () {
      $this.closest(".hover-wrapper").find(".show-content").removeClass("show-content");
    }, 500);
  };

  H.prototype.addEvents = function() {
    $(".middle-area img[alt]").hover(this.hoverIntegrations, this.hoverIntegrationsOff);
  };

  return H;
})(jQuery, window);
