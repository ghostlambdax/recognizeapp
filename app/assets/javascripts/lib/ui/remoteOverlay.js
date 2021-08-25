window.R = window.R || {};
window.R.ui = window.R.ui || {};

window.R.ui.remoteOverlay = function() {
    $document.on("click", ".remote-overlay", function(e){
      e.preventDefault();
      var path = $(this).attr("href");
      var $el = $(
        "<div class='fadeTop overlay widget-box'>" +
          "<div class='close-icon'>X</div>" +
          "<div class='overlay-wrapper'>" +
            "<div class='centeredPage' style='height:200px'>" +
              "<img src='/assets/icons/ajax-loader-medium.gif'>" +
            "</div>" +
          "</div>" +
        "</div>");
      $el.find(".overlay-wrapper").load(path);

      $body.append($el);
      R.transition.fadeTop($el);
    });
};


  