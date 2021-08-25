window.R = window.R || {};
window.R.forms = window.R.forms || {};

window.R.forms.errorList = (function($, window, body, R, undefined) {
  'use strict';

  var ul;

  var errorList = function(errors) {
    ul = document.createElement("ul");

    loop(errors);

    return ul;
  };  


  function addError(error) {
    var li = document.createElement("li");
    li.innerText = error;

    ul.appendChild(li);
  }

  function loop(errors) {
    for (var element in errors) {      
      if (errors.hasOwnProperty(element)) {
        
        if (errors[element].constructor === Array) {          
          errors[element].forEach(function(error) {
            addError(error);
          }.bind(this));
        } else {
          addError(error);
        }
        
      }
    }
  }

  return errorList;
  
})(jQuery, window, document.body, window.R);
