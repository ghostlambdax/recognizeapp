window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["admin_companies-show"] = (function($, window, undefined) {
  var AdminCompany = function() {
    this.addEvents();
  };

  AdminCompany.prototype.addEvents = function() {
    this.autoSaver = new window.R.AutoSaver();
    this.accountsDataTable = null;
    this.initUsersDatatable();
    this.bindPricePackageSelect();
    this.bindSyncFrequencySelect();
    this.bindInvoiceAdder();
    this.bindInvoiceDeleter();
    this.bindStylesheetEditor();
  };

  AdminCompany.prototype.removeEvents = function() {
    $("#user-set").off('column-visibility.dt');
    this.accountsDataTable.destroy();
    $document.off('click', '#upload-invoice');
    $document.off('click', '.delete-invoice');
  };

  AdminCompany.prototype.bindStylesheetEditor = function() {

    function saveFail(xhr, status, error) {
      try {
        var errors = new R.forms.Errors(null, xhr.responseJSON.errors);
        Swal.showValidationMessage('Request failed: ' + errors.getErrorMessagesFromErrorsObject());
        Swal.disableLoading();
        return error;
      } catch(e) {
        Swal.showValidationMessage('Request failed: ' + e);
        Swal.disableLoading();
      }
    }

    function saveStylesheet(data) {
      var ajax_data = {
        _method: 'put',
        company_customization: { stylesheet: data }
      };
      return new Promise(function(resolve, reject){
        var urlParts = $("#edit-theme-link").data('endpoint').split("?");
        var formUrl = urlParts[0] + ".js?" + urlParts[1]
        $.ajax({
          url:  formUrl,
          type: 'post',
          data: ajax_data
        }).then(function(){
          $("#edit-theme-link").data('stylesheet', data);
        }).then(resolve).fail(reject);
      }).catch(saveFail);
    }

    function compileStylesheet() {
      var urlParts = $("#edit-theme-link").data('compileendpoint').split("?");
      var formUrl = urlParts[0] + ".js?" + urlParts[1]
      return new Promise(function(resolve, reject){
        $.ajax({
          url: formUrl,
          type: 'post'
        }).then(resolve).then(function(response){
          $("#theme-edit-message").html("Theme compilation has started. <a href='/admin/queue?queue=themes'>Check status</a>")
        }).fail(reject)
      }).catch(saveFail);
    }

    $document.on(R.touchEvent, '#edit-theme-link', function(evt) {
      evt.preventDefault();
      inputPlaceholder = "$headerBg:;\n$linkColor:;\n$buttonPrimaryBg:;\n$gray:;\n@import \"application\";";
      var swalOpts = {
        icon: "info",
        title: "Update Stylesheet",
        inputValue: $("#edit-theme-link").data('stylesheet') || inputPlaceholder,
        input: "textarea",
        showCancelButton: true,
        confirmButtonText: "Save",
        reverseButtons: true,
        showLoaderOnConfirm: true,
        allowOutsideClick: function() {!Swal.isLoading()},
        preConfirm: saveStylesheet
      };
      try {
      Swal.fire(swalOpts).then(function(result){
        if(result.value) {
          Swal.fire({
            title: 'Stylesheet has been saved.',
            text: 'Press compile to deploy the new theme.',
            showCancelButton: true,
            confirmButtonText: "Compile",
            showLoaderOnConfirm: true,
            reverseButtons: true,
            allowOutsideClick: function () { !Swal.isLoading() },
            preConfirm: compileStylesheet
          }).then(function(result){
            if(result.value) {
              Swal.fire({
                title: 'Compilation in progress.',
                text: 'It should be complete in a few minutes. Check the bg tasks.'
              });
            }
          });
        }
      }).catch(function(e){
        console.log("failed here!")
      });
      } catch(e) {
        console.log("wrapped caught error")
      }
      return false;
    })
  }

  AdminCompany.prototype.bindPricePackageSelect = function() {
    this.autoSaver.autoSave("#company_price_package");
  };

  AdminCompany.prototype.bindInvoiceAdder = function(){
    var that = this;
    $document.on('click', '#upload-invoice', function(){
      var form = $(this).data('form');
      Swal.fire({
        title: 'Upload invoice',
        html: form,
        showCancelButton: false,
        showConfirmButton: false,
        onBeforeOpen: function(el) {
          that.bindInvoiceUploader();
        }
      })
    });
  };

  AdminCompany.prototype.bindInvoiceUploader = function() {
    var $uploaderForm = $("#invoice_uploader_form");
    var uploaderOpts = {
      submitBtn: $uploaderForm.find("input[type=submit]"),
      excludedCallbacks: ["add"]
    };
    new window.R.Uploader($uploaderForm, this.invoiceUploaderSuccessCallback , uploaderOpts);
  };

  AdminCompany.prototype.invoiceUploaderSuccessCallback = function(e, json) {
    Swal.close();
    Swal.fire('Success', "Your invoice has been uploaded!", 'success').then(function() {
      location.reload();
    });
  };

  AdminCompany.prototype.bindInvoiceDeleter = function() {
    $document.on('click', '.delete-invoice', function() {
      var endpoint = $(this).data('endpoint');
      Swal.fire({
        title: 'Delete invoice',
        text: "Are you sure you want to delete this Invoice?",
        showCancelButton: true,
        confirmButtonText: "Delete",
        confirmButtonColor: "#DD6B55",
        preConfirm: function() {
          return new Promise(function(resolve, reject) {
            deleteInvoice(resolve, reject, endpoint);
          }).catch(function (reason) {
            Swal.showValidationMessage(reason);
          });
        },
      });
    });
  };

  function deleteInvoice(resolve, reject, endpoint) {
    $.ajax({
      url: endpoint,
      type: "DELETE",
    }).success(function(){
      Swal.fire('Success', 'Your invoice has been deleted.', 'success').then(function(){
        location.reload();
      });
    }).fail(function(_event, request){
      var message = (request.status === 422) ?
                    'Could not delete invoice.':
                    'Something went wrong.';
      reject(message);
    })
  }

  AdminCompany.prototype.initUsersDatatable = function() {
    var that = this;
    var $table = $('#user-set');
    var timer = 0;
    var columns = [
          { data: "id", className: "not-mobile" },
          { data: "first_name" },
          { data: "last_name" },
          { data: "email" },
          { data: "phone" },
          { data: "manager" },
          { data: "teams", className: "teams-cell", orderable: false},
          { data: "roles", className: "roles not-mobile", orderable: false},
          { data: "promote_demote_link", className: "promote_demote_link", orderable: false },
          { data: "company_roles", className: "company_roles", orderable: false },
          { data: "dept", className: "department" },
          { data: "country", className: "country" },
          { data: "status", className: "status" },
          { data: "created_at", className: "not-mobile" },
          { data: "edit_link", orderable: false },
          { data: "activate_link", className: "activate-disable-cell", orderable: false }
      ];
    //FIXME - add column for network if company is in family(ie depts)
    if($("#user-set th.dept").length === 1) {
      // Attention: If adding/removing columns affect desired position of 'network' column,
      // readjust index in the 'splice' function below.
      columns.splice(4, 0, {data: "network", className: "not-mobile"});
    }

    var datatableOptions = {
      colvis: {
        enabled: true,
        insertButtonBeforeSelector: "#user-set_length",
        columnsToShowByDefault: ["first_name", "last_name", "email", "status", "edit_link", "activate_link"]
      },
      order: [[ 1, "asc" ], [2, "asc"], [3, "asc"]]
    };

    that.accountsDataTable = window.R.utils.createDataTable(columns, $table,  datatableOptions);

    $table.on( 'draw.dt column-visibility.dt', function () {
      that.addTableEvents();
    });
  };


  AdminCompany.prototype.bindRolesSelect = function($target) {
    new window.R.Select2(function () {
      AdminCompany.prototype.initializeRolesSelect2();

      if (!AdminCompany.prototype.bindRolesSelect.loadedEvents) {
        $document.on('select2:select', '.user-company-role-select', function(event) {
          $.ajax({
            url: $(this).data("url"),
            data: { role_id: event.params.data.id },
            method: "post"
          });
        });

        $document.on('select2:unselect', '.user-company-role-select', function(event) {
          $.ajax({
            url: $(this).data("url"),
            data: { role_id: event.params.data.id, _method: "delete" },
            type: "post"
          });
        });

        AdminCompany.prototype.bindRolesSelect.loadedEvents = true;
      }
    });
  };

  AdminCompany.prototype.bindTeamsSelect = function() {
    new window.R.Select2(function() {
      AdminCompany.prototype.initializeTeamsSelect2();

      if (!AdminCompany.prototype.bindTeamsSelect.loadedEvents) {
        $document.on('select2:select', '.user-team-select', function(event) {
          $.ajax({
            url: $(this).data("url"),
            data: { team_id: event.params.data.id },
            method: "post"
          });
        });

        $document.on('select2:unselect', '.user-team-select', function(event) {
          $.ajax({
            url: $(this).data("url"),
            data: { team_id: event.params.data.id, _method: "delete" },
            type: "post"
          });
        });

        AdminCompany.prototype.bindTeamsSelect.loadedEvents = true;
      }
    });
  };

  AdminCompany.prototype.bindManagerAutocomplete = function($target) {
    new window.R.Select2(function () {
      var $table = $('#user-set');

      var url = "/coworkers";
      var network = $table.data('network');
      if(network) {
        url = url + "?network="+network;
      }

      if ($target === undefined) {
        $target = $(".manager-select");
      }

      $($target.selector + ':not(.select2-hidden-accessible)').select2({
        ajax: {
          url: url,
          dataType: 'json',
          delay: 250,
          data: function (params) {
            return {
              term: params.term, // search term
              page: params.page,
              include_self: true
            };
          },
          processResults: function (data, page) {
            return {
              results: data
            };
          },
          cache: true
        },
        escapeMarkup: function (markup) {
          return markup;
        },
        minimumInputLength: 1,
        templateResult: formatUser,
        templateSelection: formatUserSelection,
        allowClear: true,
        placeholder: ''
      });
    });

  };

  AdminCompany.prototype.bindManagerSelect = function() {
    if (!AdminCompany.prototype.bindManagerSelect.loadedEvents) {
      $document.on('select2:select', '.manager-select', function (e) {
        $.ajax({
          url: $(this).data("url"),
          data: { manager_id: e.params.data.id, user_id: $(this).data("user") },
          method: "post"
        });
      });
      $document.on('select2:unselect', '.manager-select', function(event) {
        $.ajax({
          url: $(this).data("url"),
          type: "post"
        });
      });
      AdminCompany.prototype.bindManagerSelect.loadedEvents = true;
    }
  };

  AdminCompany.prototype.initializeRolesSelect2 = function($target) {
    if ($target === undefined) {
      $target = $(".user-company-role-select");
    }
    $($target.selector + ':not(.select2-hidden-accessible)').select2({
      tokenSeparators: [',', ' ']
    });
  };

  AdminCompany.prototype.initializeTeamsSelect2 = function($target) {
    if ($target === undefined) {
      $target = $(".user-team-select");
    }
    $($target.selector + ':not(.select2-hidden-accessible)').select2({
      tokenSeparators: [',', ' ']
    });
  };

  AdminCompany.prototype.bindSyncFrequencySelect = function() {
    this.autoSaver.autoSave("#sync_frequency");
  };

  // See `Accounts.prototype.updateUserRow` for comments.
  AdminCompany.prototype.updateUserRow = function(rowSelector, updatedUserRowData) {
    this.accountsDataTable.row(rowSelector).data(updatedUserRowData);
    this.reinitializeRowComponents(rowSelector);
  };

  // Used by `activate` and `destroy` actions
  AdminCompany.prototype.reinitializeRowComponents = function(row) {
    var $row = row instanceof $ ? row : $(row);
    var $companyRoleSelect = $row.find("select.user-company-role-select");
    var $teamSelect = $row.find("select.user-team-select");
    var $managerSelect = $row.find("select.manager-select");
    this.initializeRolesSelect2($companyRoleSelect);
    this.initializeTeamsSelect2($teamSelect);
    this.bindManagerAutocomplete($managerSelect);
  };



  AdminCompany.prototype.addTableEvents = function() {
    this.bindRolesSelect();
    this.bindTeamsSelect();
    this.bindManagerAutocomplete();
    this.bindManagerSelect();
  };

  function formatUser(user) {
    if (user.loading) {
      return "Please wait";
    }

    if (user.avatar_thumb_url === R.defaultAvatarPath) {
      user.avatar_thumb_url = "/assets/" + R.defaultAvatarPath;
    }

    var raw_template = $('#user_avatar_template').html();
    var template = Handlebars.compile(raw_template);
    return template({
      "avatar_url": user.avatar_thumb_url,
      "name": user.label
    });
  }

  function formatUserSelection(user) {
    return user.label || user.text;
  }
  return AdminCompany;
})(jQuery, window);
