window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_tskz_completed_tasks-index"] = (function() {
  "use strict";

  var CompletedTasks = function() {
    this.$table = R.LitaTables['completed_tasks'].$table;
    this.$table.on('draw.dt', function(){
      this.removeTableEvents();
      this.addTableEvents();
    }.bind(this));
    this.$table.on('xhr.dt', this.insertOrUpdateTotalPoints.bind(this));

    this.addEvents();
  };

  CompletedTasks.prototype.addEvents = function() {
    new R.CompanyAdmin();
  };

  // Note: this method is used by Litatable.js
  CompletedTasks.prototype.renderGroupRow = function(rowGroup, rows, group) {
    var totalColumns = rowGroup.s.dt.columns()[0].length;
    var remainingColumnSpan = totalColumns-4;
    var rowsData = rows.data().reduce(function(a,b){a.push(b);return a}, [])

    var source = $("#completed_tasks-row-group-template").html();
    var template = Handlebars.compile(source);
    var row = rowsData[0];
    return template(row);

  };

  CompletedTasks.prototype.showTaskSubmissionResolutionModal = function(evt) {
    window.R.utils.remoteSwal({
      customClass: 'task-submission-swal',
      width: '60%',
      onOpen: function(el) { loadResolutionForm(el, evt); },
      preConfirm: submitResolutionForm
    }).then(function(result){/* noop */});

  };

  // Insert / update total points label above table
  CompletedTasks.prototype.insertOrUpdateTotalPoints = function(_evt, _settings, responseJSON) {
    if (isNaN(responseJSON.totalPoints))
      return;

    if (!this.$totalPointsContainer)
      this.$totalPointsContainer = createTotalPointsContainer(this.$table);

    this.$totalPointsContainer.html(responseJSON.totalPoints);
  };

  CompletedTasks.prototype.addTableEvents = function() {
    $document.on(R.touchEvent, '.resolve-task-submission-link', this.showTaskSubmissionResolutionModal);
  };

  CompletedTasks.prototype.removeTableEvents = function() {
    $document.off(R.touchEvent, '.resolve-task-submission-link')
  };

  CompletedTasks.prototype.removeEvents = function() {
    this.removeTableEvents();
  };

  function loadResolutionForm(el, evt) {
    var $el = $(el), 
        $target = $(evt.target),
        $swalContent = $el.find('.swal2-content #swal2-content');

    // hide h2 title so we have full control of modal layout
    $swalContent.closest(".swal2-modal").find("h2").hide();

    $.ajax({
      url: $target.data('editendpoint')
    }).done(function(data){
      $swalContent.html(data);
    });

  }

  function handleSuccessfulResolution(resolve) {
    $("#completed_tasks-table_wrapper table").DataTable().ajax.reload();
    var swalFadeOutTime = 2000;
    setTimeout(resolve, swalFadeOutTime);
    Swal.fire({
      icon: 'success',
      showConfirmButton: false,
      timer: swalFadeOutTime
    });
  }

  function handleErroneousResolution(evt, id, errors) {
    var errorMessage = new window.R.forms.Errors(null, errors).getErrorMessagesFromErrorsObject().join("<br>");
    Swal.showValidationMessage(errorMessage);
    $(Swal.getCancelButton()).prop('disabled', false); // https://github.com/sweetalert2/sweetalert2/issues/1501
  }

  function submitResolutionForm() {
    return new Promise(function(resolve){
      $document.on('ajaxify:success:edit_task_submission', function(){
        handleSuccessfulResolution(resolve);
        $document.off('ajaxify:success:edit_task_submission');
      });

      // Handle errors manually since form input ids wont match what comes back from response.
      $window.bind("ajaxify:errors:edit_task_submission", function(evt, id, errors){
        handleErroneousResolution(evt, id, errors);
        $window.unbind("ajaxify:errors:edit_task_submission");
      });

      $document.find(".swal2-modal form").submit();
    });
  }

  function createTotalPointsContainer(table) {
    var $wrapper = $('<div>', { class: 'total-points-wrapper' });
    var $label = $('<span>', { title: 'Total points that have been approved', html: 'Total Points<sup>?</sup>: ' });
    var $points = $('<span>', { class: 'total-points' });
    $wrapper.append($label, $points);
    $(table).before($wrapper);

    if ($label.tooltip)
      $label.tooltip();

    return $points;
  }

  return CompletedTasks;
})();

window.R.pages["manager_admin_tskz_completed_tasks-index"] = window.R.pages["company_admin_tskz_completed_tasks-index"];
