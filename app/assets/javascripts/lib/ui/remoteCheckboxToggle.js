window.R = window.R || {}; 
window.R.ui = window.R.ui || {}; 

window.R.ui.remoteCheckboxToggle = (function($, window, body, undefined) {

  function handleChange() {
    var $target = $(this.elem), data = {}, type = null;
    var endpoint = $target.data('endpoint');    
    var checkedValue = !!this.elem.prop("checked");
    if ($target.data('invert-values') === true) { // used as `invert_values` in view
      checkedValue = !checkedValue;
    }
    data[$target.prop('name')] = checkedValue;
    type = $target.data('method') || "POST"

    if(endpoint) {
      $.ajax({
        url: endpoint,
        type: type,
        data: data
      })            
    } else {
      console.warn("Endpoint data attribute is missing on checkbox")
    }
  }

  return function() {
    $(".remoteCheckboxToggle").each(function(index, el) {

      $(el).iOSCheckbox({
        onChange: handleChange
      });

    }.bind(this));    
  }

})(jQuery, window, document.body);
