window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["admin_index-index"] = (function($, window, undefined) {
  return function() {
    this.pagelet = new window.R.Pagelet();

    $("#admin-graph").bind("pageletLoaded", function(){
      var graph = R.ui.graph();
    });

    $document.on(R.touchEvent, "#refresh-cms-btn", function(evt) {
      evt.preventDefault();
      Swal.fire({
        icon: 'info',
        showCancelButton: true,
        focusConfirm: true,
        title: "Refresh CMS Cache?",
        html: "<p style='text-align:left'>This will remove and repopulate the Wordpress/CMS cached files. This is a safe operation (but use sparingly). This will be done in the priority-caching bg queue.</p>",
        confirmButtonText: 'Go for it!',
        reverseButtons: true,
        showLoaderOnConfirm: true,
        allowOutsideClick: function(){ !Swal.isLoading()},
        preConfirm: function(login) {
          const csrfToken = document.querySelector("[name='csrf-token']").content;          
          return fetch('/admin/refresh_cms_cache', {
            method: 'POST',
            headers: {
              "X-CSRF-Token": csrfToken, // 👈👈👈 Set the token
              "Content-Type": "application/json"
            },            
          }).then(function(response) {
              if (!response.ok) {
                throw new Error(response.statusText);
              }
              return response.json();
            })
            .catch(function(error) {
              Swal.showValidationMessage('Request failed: '+error);
            })
        },        
      }).then(function(result){
        if(result.value.success === true) {
          Swal.fire({
            icon: 'success',
            title: 'Refreshing the cache has commenced!',
            text: 'It may take a few minutes. Check back in a bit. Also, you can check the bg jobs to see when it clears',
            showConfirmButton: true
          })          
        } else {
          Swal.fire({
            icon: 'error',
            title: 'There was a problem creating the job. Check the exception logs or server logs.',
            showConfirmButton: true
          })             
        }

      });
      return false;
    });
  }
})(jQuery, window);
