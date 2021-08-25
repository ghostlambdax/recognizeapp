window.R = window.R || {};

window.R.AutoSaver = (function($, window, body, R, undefined){

  var AutoSaver = function() {
  };

  function renderMessage(message, $setting, fadeOutTime, textColor){
    var $message = $("<span class='message'>").html(message);
    $message.css({marginLeft: "10px", color: textColor});
    $setting.siblings("label").append($message);
    $message.fadeOut(fadeOutTime);
  }

  AutoSaver.prototype.autoSave = function(settingSelector, done, fail, always, abort){
    $document.on('change', settingSelector, function(){
      var $setting = $(this);
      var endpoint = $setting.data('endpoint') || $setting.parents('form').prop('action');

      var data = {};

      data[$setting.prop('name')] = $setting.val();

      if(abort && abort($setting)) {
        return;
      }

      var promise = $.ajax({
        url: endpoint,
        type: 'PUT',
        data: data,
        dataType: 'json'
      });

      promise.done(function(){
        renderMessage("Saved!", $setting, 3000, "green");
      }).fail(function(){
        renderMessage("Something went wrong. Please refresh and retry.", $setting, 5000, "red");
      }).done(done).fail(fail).always(always);
    });
  };
  return AutoSaver;
})(jQuery, window, document.body, window.R);