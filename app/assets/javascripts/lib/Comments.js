window.R = window.R || {};

window.R.Comments = (function($, window, body, R, undefined) {
  var NAMESPACE = "#comments-";
  var Comments;
  var turbolinkEvent = "turbolinks:before-cache";

  Comments = function( afterAddCallback) {
    this.addEvents();
    this.afterAddCallback = afterAddCallback || function() {};
  };

  Comments.prototype.addEvents = function() {
    $window.bind("ajaxify:success:comment_add", this.add.bind(this));
    $window.bind("ajaxify:errors", this.handleError);
    $body.on("keyup", ".comments-wrapper .input-xlarge", function() {
      var $btn = $(this).parent().next();
      if (this.value.trim() !== "") {
        $btn.attr("disabled", null);
      } else {
        $btn.attr("disabled", "disabled");
      }
    });
    $body.on("focusin", ".comments-wrapper .input-xlarge", function() {
      if (this.value.length === 0) {
        var $btn = $(this).parent().next();
        $btn.attr("disabled", "disabled");
      }

    });
    $body.on("focusout", ".comments-wrapper .input-xlarge", function() {
      var $btn = $(this).parent().next();
      $btn.attr("disabled", null);
    });

    $document.bind(turbolinkEvent, this.removeEvents.bind(this));
  };

  Comments.prototype.removeEvents = function() {
    $window.unbind("ajaxify:success:comment_add");
    $window.unbind("ajaxify:errors", this.handleError);
    $document.unbind(turbolinkEvent, this.removeEvents.bind(this));
  };

  Comments.prototype.add = function(e, data) {
    var data = data.data.params;
    var wrapperId = NAMESPACE + data.recognition_id;
    $(".no-comments").hide();
    $(wrapperId + " .comment_content").val("");
    $(wrapperId + " .comments-list-wrapper").prepend( $( data.comment ) );
    this.afterAddCallback();

    $document.trigger("recognition:change");
  };

  Comments.prototype.handleError = function(e, formId, errors) {
    var errorMessage = (errors.comment_content || [])[0];
    if (errorMessage) {
      $('#'+formId +' .controls').prepend("<div class=error><h5>"+errorMessage+"</h5></div>");
    }

    $("#"+formId + " .button").attr("disabled", null);

    $document.trigger("recognition:change");
  };
  
  return Comments;
  
})(jQuery, window, document.body, window.R);