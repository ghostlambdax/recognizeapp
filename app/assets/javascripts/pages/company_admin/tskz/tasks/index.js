window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_tskz_tasks-index"] = (function() {
  "use strict";
  var Tasks = function() {
    this.addEvents();
  };

  Tasks.prototype.addEvents = function() {
    new R.CompanyAdmin();
    $document.on("ajax:complete", "a.task-status-toggle[data-remote]", taskStatusToggle);
  };
  return Tasks;
})();

function taskStatusToggle(e) {
  "use strict";
  var $this = $(e.target);
  $this.text($this.data('task-status'));
}