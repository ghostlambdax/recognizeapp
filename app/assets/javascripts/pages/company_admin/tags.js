window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_tags-index"] = (function() {
  'use strict';

  var Tags = function() {
    this.addEvents();
  };

  Tags.prototype.addEvents = function() {
    this.companyAdmin = new R.CompanyAdmin();
    this.bindTagTypeToggle();

  };

  Tags.prototype.removeEvents = function() {
    this.unbindTagTypeToggle();
  };

  Tags.prototype.bindTagTypeToggle = function() {
    $document.on('change', '.tag-type-toggle', function(e) {
      var tagData = { };
      var tagType = this.name;
      //`tagType` is dynamic; can be either `is_recognition_tag` or `is_task_tag`.
      tagData[tagType] = this.checked;

      $.ajax({
        url: $(this).data('endpoint'),
        type: "PATCH",
        data: tagData,
        success: function() {
          // noop
        }
      });
    });
  };

  Tags.prototype.unbindTagTypeToggle = function() {
    $document.off('change', '.tag-type-toggle');
  };

  return Tags;

})();
