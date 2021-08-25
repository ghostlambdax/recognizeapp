window.R = window.R || {};
window.R.pages = window.R.pages || {};

["task_submissions-new_chromeless", "task_submissions-new"].forEach(function(page) {
  window.R.pages[page] = (function() {
    var addTaskSelector = '#add-task';
    var taskListSelector = '#task-list';

    // this is only needed for grouping the form fields inside each individual task
    // so it only needs to be unique for every task & thus is not adjusted when removing
    var taskCount = 1;

    var TaskSubmission = function () {
      this.addEvents();
    };

    var initializeSelect2 = function ($taskElem) {
      new window.R.Select2(function () {
        $taskElem.find('.name').select2();
      });
    };

    var addNewTask = function ($refTaskElem) {
      var $newTaskElem = cloneTask($refTaskElem);
      $(taskListSelector).append($newTaskElem);
      taskCount += 1;
      initializeSelect2($newTaskElem);
    };

    var cloneTask = function ($elem) {
      // var regex = /\[(\d+)]/;
      $elem = $elem.clone();
      $elem.children('input, select').each(function() {
        if (this.name)
          this.name = this.name.replace('[0]', '[' + taskCount + ']');
      });
      return $elem;
    };

    var cloneInitialTask = function ($elem) {
      var $clonedElem = $elem.clone();
      $clonedElem.children('input, select').each(function () {
        // ids are not used currently, so avoid the duplication by removing them entirely
        this.removeAttribute('id');
        // remove selected values from any previous navigation
        $(this).val('');
      });
      $clonedElem.find('select > option').each(function () {
        $(this).attr('selected', null);
      });
      return $clonedElem;
    };

    TaskSubmission.prototype.addEvents = function() {
      var $initialTasks = $(taskListSelector).find('.task');
      var $refTaskElem = cloneInitialTask($initialTasks.first());
      initializeSelect2($initialTasks);

      $(addTaskSelector).click(function (e) {
        e.preventDefault();
        addNewTask($refTaskElem);
      });

      $(taskListSelector).on('click', '.remove-task', function () {
        $(this).parent().remove();
      });
    };

    TaskSubmission.prototype.removeEvents = function() {
      $(addTaskSelector).off('click');
      $(taskListSelector).off('click');

      // preserve task selections on page restore
      R.utils.saveSelectValuesToDom(taskListSelector);
    };

    return TaskSubmission;
  })();
});