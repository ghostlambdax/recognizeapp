(function() {
  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.overlay = {
    init: init,
    open: open,
    close: close
  };

  var html = '<script id="r-overlay" type="text/x-handlebars-template">\n' +
      '  <div role="dialog" aria-labelledby="yj-simple-lightbox--title" data-qaid="lightbox" class=" r-hidden yj-simple-lightbox">\n' +
      '    <div class="yj-simple-lightbox--content yj-create-lightbox-group r-overlay-wrapper" role="document">\n' +
      '      <span tabindex="-1" style="position:absolute; left:0px; top:0px"></span>\n' +
      '      {{#if title}}\n' +
      '        <h1 id="yj-simple-lightbox--title" data-qaid="lightbox-title" class="yj-simple-lightbox--header-bar">\n' +
      '          {{title}}\n' +
      '        </h1>\n' +
      '      {{/if}}\n' +
      '      <div role="button" class="yj-simple-lightbox--header-close-button" data-speechtip="" data-qaid="lightbox-close">\n' +
      '        <span class="yamicon yamicon-x yamicon-xx-small"></span>\n' +
      '        <span class="yj-acc-hidden">Close</span>\n' +
      '      </div>\n' +
      '      <div data-qaid="lightbox-content" class="yj-simple-lightbox--content-container "  style="overflow: hidden; min-height: 665px;">\n' +
      '        {{{content}}}\n' +
      '      </div>\n' +
      '    </div>\n' +
      '  </div>\n' +
      '</script>\n' +
      '\n' +
      '<script id="r-iframe" type="text/x-handlebars-template">\n' +
      '  <iframe id="{{id}}" src="{{url}}" style="height: 550px; width: 100%;"></iframe>\n' +
      '</script>'

  var template;
  var $overlay;

  function init(callback) {
    $body.append(jQuery(html));
    template = Handlebars.compile(jQuery('#r-overlay').html());

    if (callback) {
      callback();
    }

    $body.on('click', '.yj-simple-lightbox--header-close-button', close);
  }

  function open(title, body, size) {
    var overlayHTML, position, completeOpen, width, height;



    completeOpen = function() {
      $overlay = jQuery('.r-overlay-wrapper');

      overlayHTML = template({
        title: title,
        content: body
      });

      close();

      $body.append(jQuery(overlayHTML));

      $overlay = jQuery('.r-overlay-wrapper');

      if (size === "full") {
        width = jQuery(window).width() - 50;
        enlarge(width, 650);
      }

    };

    if (!template) {
      init(function() {
        completeOpen();
      });
    } else {
      completeOpen();
    }
  }

  function close() {
    if ($overlay.length > 0) {
      $overlay.closest(".yj-simple-lightbox").remove();
    }
  }

  function enlarge(width, height) {
    $overlay = jQuery('.r-overlay-wrapper').removeClass('r-hidden');
    width = width || $overlay.width();
    height = height || $overlay.height();

    $overlay.css({
      'width': width + 'px'
    });

    $overlay.find("iframe").css({
      'height': height + 'px'
    });

    $overlay.closest(".yj-simple-lightbox").css({
      "padding-top": "50px"
    });

  }
})();
