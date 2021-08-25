window.R = window.R || {};
window.R.ui = window.R.ui || {};
window.R.ui.FavoriteTeam = (function($, window, body, undefined) {
  var FavoriteTeam = function() {
    this.addEvents();
  };

  FavoriteTeam.prototype.addEvents = function() {
    $document.on('change', ".checkbox-wrapper.favorite-team", function(){
      var $container = $(this);
      var $target = $container.find('input'), data = {};
      data['team_id'] = $target.data('team-id');
      data['add'] = $target.prop("checked") ? true : false;
      var title = $target.data('error-title');
      $.ajax({
        url: '/'+ $('body').data('name')+'/update_favorite_teams',
        type: "POST",
        data: data,
        error: function(jqXHR) {
          if (jqXHR.status == 422) {
            displayFeedback(jqXHR.responseJSON.errors.favorite_team_ids[0], title)
            $target.prop("checked", !$target.prop("checked"))
          }
        }
      });
    });
  };

  FavoriteTeam.prototype.removeEvents = function() {
    $document.off('change', ".checkbox-wrapper.favorite-team");
  };

  function displayFeedback(message, title){
    Swal.fire({
      title: title,
      html: message,
      icon: 'error',
      showCancelButton: false,
      confirmButtonText: 'Okay'
    });
  }
  return FavoriteTeam;

})(jQuery, window, document.body);