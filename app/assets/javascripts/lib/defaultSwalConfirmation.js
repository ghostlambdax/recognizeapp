// default confirmation being replaced by swal
(function () {
  'use strict';
  //Override the default confirm dialog by rails
  if (window.Swal && window.R.confirmationDialog) {
    $.rails.allowAction = function(link){
      if (link.data("confirm") === undefined || link.data("confirm") === null ){
        return true;
      }
      $.rails.showConfirmationDialog(link);
      return false;
    };

    //User click confirm button
    $.rails.confirmed = function(link){
      $(link).one("ajax:complete", function(e) {
        $(e.target).data("confirm", link.data('confirmText'));
      });

      link.data("confirmText", link.data('confirm'));
      link.data("confirm", null);
      link.trigger("click.rails");
    };

    //Display the confirmation dialog
    $.rails.showConfirmationDialog = function(link){
      var message = link.data("confirm"),
          title = link.data("title") || window.R.confirmationDialog.confirmationTitle,
          customClass = link.data("custom-class"),
          iconType = 'warning',
          confirmButtonText = link.data("confirm-button-text") || window.R.confirmationDialog.confirmButtonText;
      Swal.fire({
        title: title,
        text: message,
        icon: iconType,
        confirmButtonText: confirmButtonText,
        customClass: customClass,
        showCancelButton: true
      }).then(function(result) {
        if (result.value){
          $.rails.confirmed(link);
        }
      });
    };
  }
}());
