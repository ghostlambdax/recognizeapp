(function() {
  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.overlay = {
    init: init,
    open: open,
    close: close
  };

  var template;
  var $overlay;

  function init(callback) {
    Recognize.ajax({
        url: Recognize.file.getPath('templates/overlay.html'),
        success: function(html) {

            $body.append(jQuery(html));
            template = Handlebars.compile(jQuery('#r-overlay').html());

            if (callback) {
              callback();
            }

        }.bind(this)
    });

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
