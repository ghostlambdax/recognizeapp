window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_tskz_tasks-new"] = window.R.pages["company_admin_tskz_tasks-edit"] = (function() {
  "use strict";

  var Task = function() {
    this.addEvents();
  };

  var rolesPlaceholder = "Roles";

  Task.prototype.addEvents = function() {
    new R.CompanyAdmin();
    this.bindRolesSelect();
    this.bindTagSelect();
  };

  Task.prototype.removeEvents = function() {
    // preserve tag/role selections on page restore
    R.utils.saveSelectValuesToDom('#tskz_new_tskz_task');
  };

  Task.prototype.bindRolesSelect = function() {
    new window.R.Select2(function () {
      $('.company-role-select').select2({
        tokenSeparators: [',', ' '],
        placeholder: window.R.utils.isIE() !== false && window.R.utils.isIE() < 12 ? '' : rolesPlaceholder
      });
    });
  };

  Task.prototype.bindTagSelect = function() {
    new window.R.Select2(function () {
      var $tagSelect = $('#tskz_tskz_task_tag_name');
      var tagPlaceholder = $tagSelect.attr('placeholder');
      $tagSelect.select2({
        placeholder: window.R.utils.isIE() !== false && window.R.utils.isIE() < 12 ? '' : tagPlaceholder
      });
    });
  };
  return Task;
})();
