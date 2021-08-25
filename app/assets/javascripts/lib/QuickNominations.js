window.R = window.R || {};

window.R.QuickNominations = function() {
  'use strict';

  function formatItem(item) {
    if (!item.id) { return item.text; }
    var $item = item.text;
    return $item;
  }

  var statusFilter = window.R.utils.queryParams().status;
  var disableQuickNoms = statusFilter == "denied";

  new window.R.Select2(function(){
    $("select.quick-nomination").select2({
      templateResult: formatItem,
      minimumResultsForSearch: Infinity,
      disabled: disableQuickNoms
    });
  });

  function clearQuickNominationSelection(evt) {
    var $el = $(evt.target);
    var vals = $el.select2().val();
    vals.splice(vals.indexOf(evt.params.data.id));
    $el.select2().val(vals);
    $el.select2().trigger('change');    
  }

  function sendQuickNomination(evt) {
    var $target = $(evt.target);
    var url = $target.data('endPoint');
    var badgeId = evt.params.data.id;
    var recipientId = $target.data('recipientId');
    var recognitionId = $target.closest("tr").prop('id').split("-")[0]; // rows have id <slug>-<recipientid>

    $.ajax({
      url: url,
      type: 'post',
      dataType: 'json',
      data: {
        nomination_vote: {
          is_quick_nomination: true,
          nomination: {
            badge_id: badgeId
          },
          recipients: ["User:"+recipientId],
          recognition_slug: recognitionId
        }
      },
      error: function(xhr){
        clearQuickNominationSelection(this);

        Swal.fire({
          icon: 'warning',
          html: window.R.forms.errorList(xhr.responseJSON.errors)
        });
      }.bind(evt)
    });
  }

  $("select.quick-nomination").on('select2:select', function(evt) { 
    Swal.fire({
      icon: 'info',
      text: "Are you sure you want to nominate this user for this award?",
      showCancelButton: true
    }).then( function(result) {
        if (result.value) {
          sendQuickNomination(this);
        } else {
          clearQuickNominationSelection(this);
        }
      }.bind(evt)
    );
  });

  /*************************************************
  * START HACK SELECT2 v4.x does not support locking items
  * remove this code block when this feature is supported
  * See: https://github.com/select2/select2/issues/3339
  */
  $(document).on("select2:unselecting", 'select:not([multiple])', function (e)
  {
      e.preventDefault();
      if ($(e.params.args.data.element).attr('locked'))
          return false;
      $(this).val('').trigger("change");
      // $(this).select2('val', '');
  });
  $(document).on("select2:selecting", 'select:not([multiple])', function (e)
  {
      if ($(e.target).find(":selected").attr('locked'))
          return false;
  });
  $(document).on('select2:unselecting', 'select[multiple]', function(e)
  {
      $(e.target).data('unselecting', true);
      if ($(e.params.args.data.element).attr('locked'))
          return false;

  }).on('select2:open', function(e)
  {
      var $target = $(e.target);
      if ($target.data('unselecting'))
      {
          $target.removeData('unselecting');
          $target.select2('close');
      }
  });
  /**************************************************
  * END HACK UNTIL SELECT2 v4.x supports locking items
  ***************************************************/
};
