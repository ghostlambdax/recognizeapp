window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_documents-index"] = (function() {
  'use strict';


  var Documents = function() {
    this.addEvents();
    new R.CompanyAdmin();
  };

  Documents.prototype.addEvents = function(){
    this.setupDocumentUploader();
  };

  Documents.prototype.removeEvents = function(){
  };

  Documents.prototype.setupDocumentUploader = function(){
    var that = this;

    var $uploaderForm = $("form#new_document");

    var uploaderOpts = {
      max_file_upload_size_in_mb: gon.max_file_upload_size_in_mb,
      submitBtn: $uploaderForm.find("input[type=submit]")
    };
    // Bind jquery file uploader.
    new window.R.Uploader($uploaderForm, that.uploaderSuccessCallback, uploaderOpts);
  };

  Documents.prototype.uploaderSuccessCallback = function(e, json){
    R.utils.redrawDatatable($("#documents-table"));

    $("#success_feedback").remove();
    $(".file-attach-progress .message").before("<span id='success_feedback'>" + json.message + "</span>");
    $("#success_feedback").fadeOut(2000);
    $("form#new_document").trigger('reset');
  };

  return Documents;
})();
