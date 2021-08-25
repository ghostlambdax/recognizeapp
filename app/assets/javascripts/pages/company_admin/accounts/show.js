window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_accounts-show"] = (function() {
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

  var Accounts = function() {
    this.accountsDataTable = null;
    this.dynamicUserTeamCreator = new DynamicUserTeamCreator();
    this.addEvents();
  };

  Accounts.prototype.addEvents = function() {
    var companyAdmin = new R.CompanyAdmin();

    // Bulk edit view can be displayed initially on turbolinks restore, if it was open on last navigation
    if ($('#edit_bulk_user_updater').length) {
      this.initializeEditAccountDataTable();
    } else {
      // default users table view
      // note: these bindings are not needed above when the initial view is bulk edit,
      // because a turbolinks request is issued when returning back from that page to this (vice-versa is not true)
      this.bindAccountsPageEvents();
    }

    this.bindBulkEditPageEvents();
  };

  Accounts.prototype.bindAccountsPageEvents = function() {
    this.bindAccountsPagelet();
    this.bindEditAccountsBtn();
    this.bindInviteEmailerButton();
    this.bindShowForgottenPasswordLink();
    this.bindResetPasswordLink();
  };

  Accounts.prototype.bindBulkEditPageEvents = function() {
    this.bindLeaveEditAccountsBtn();
    this.bindAccountsSuccess();
    this.bindAccountsError();
    this.bindAddAccountBtn();
  };

  Accounts.prototype.addTableEvents = function() {
    this.bindRolesSelect();
    this.bindTeamsSelect();
    this.bindManagerAutocomplete();
    this.bindManagerSelect();
  };

  Accounts.prototype.removeEvents = function() {
    $document.off('click', '#invite-accounts');
    $document.off('click', '#leave-edit-accounts');
    $document.off('click', '#add-account');
    $document.off('click', 'a#edit-accounts');
    $document.off('click', '#new_bulk_mailer_form .button-group .button');
    $document.off('click', '#show-forgotten-password-link');
    $document.off('click', '#template-tags .badge');
    $document.off('click', '#sms-template-tags .badge');

    $(".manager-select").off();
    $("#user-set").off('column-visibility.dt');
    $('#response-feedback-wrapper').empty();

    $document.off('ajaxify:success', '.edit_bulk_user_updater');
    $document.unbind('ajaxify:error:edit_bulk_user_updater');

    if (this.editAccountsDatatable) {
        this.editAccountsDatatable.destroy();
    }
  };

  Accounts.prototype.bindEditAccountsBtn = function() {
    var that = this;

    $.fn.dataTable.ext.order['dom-checkbox'] = function(settings, col) {
      return this.api().column(col, { order: 'index' }).nodes().map(function(td, i) {
        return $('input', td).prop('checked') ? '1' : '0';
      });
    };

    $document.on('click', "a#edit-accounts", function(e) {
      e.preventDefault();

      var url = $(e.target).attr('href');
      window.recognize.patterns.formLoading.setNonAjaxButton(e);

      $("#accounts").load(url + " #wrapper-outer .wrapper form", function() {
        window.recognize.patterns.formLoading.resetButton();
        that.initializeEditAccountDataTable();
      });
      return false;
    });
  };

  Accounts.prototype.initializeEditAccountDataTable = function() {
    var that = this;
    var $table = $("#edit-accounts table");

    this.editAccountsDatatable = $table.DataTable({
      ordering: true,
      paging: true,
      searching: true,
      responsive: false,
      pageLength: 100,
      "columnDefs": [{ "orderDataType": "dom-checkbox", targets: [3] }],
      // this adds forced preliminary sorting (for 3rd column), for positioning new unsaved rows at the top
      "aaSortingFixed": [[2, 'desc']]
    });

    $table.dataTable().fnSetFilteringDelay();

    $table.on("draw.dt", function(){
      $("#edit-accounts").off("change keyup", "input:not([type=checkbox]), select");
      that.setDatePicker();
    });

    $table.on("order.dt", function(){
      $.each($(this).find("tbody tr"), function(){
        $(this).removeClass("selected");
      });
    });
    that.setDatePicker();
  };

  Accounts.prototype.bindAccountsPagelet = function() {
    var that = this;

    that.accountsDataTable = R.LitaTables['accounts'].dataTable;

    R.LitaTables['accounts'].$table.on( 'draw.dt column-visibility.dt', function () {
      that.addTableEvents();
    });

    new window.R.Select2(function () {
      $(".litatable-filters .select2").select2();
    });
  };

  Accounts.prototype.bindLeaveEditAccountsBtn = function() {
    var that = this;
    $document.on('click', "#leave-edit-accounts", function(e) {
      e.preventDefault();
      var url = $(e.target).attr('href');

      window.recognize.patterns.formLoading.setNonAjaxButton(e);

      Turbolinks.visit(url);

      return false;
    });

  };

  Accounts.prototype.bindAccountsSuccess = function() {
    var that = this;
    $document.on('ajaxify:success', '.edit_bulk_user_updater', function(e, successObj) {
      var numAccountsCreated = successObj.data.bulk_user_updater.created_users.length;
      var numAccountsUpdated = successObj.data.bulk_user_updater.updated_users.length;
      var msg;
      var table = $("#edit-accounts table").dataTable().api();
      if (numAccountsCreated > 0) {
        // need to update the rows for created records and make them "updates"
        $.each(successObj.data.bulk_user_updater.created_users, function() {
          var $row = $("#user-row-" + this.temporary_id),
            temporaryId = this.temporary_id,
            actualId = this.id,
            birthday = this.birthday,
            startDate = this.start_date;

          $row.find("td").each(function() {
            var $cellEl = $(this);
            $cellEl.find("input").each(function() {
              var $this = $(this);
              var val = $this.val();

              $this.attr("value", val);
              // set sort value for cell (if relevant sort attr present and current input is visible)
              if ($cellEl.attr('data-order') !== undefined && $this.attr('type') !== 'hidden') {
                var $parentTd = $(this).parent("td");

                var dataOrder = val;
                var attrId = $this.attr("id");
                // sorting and searching works with dd-mm-yyyy format
                if (attrId === "bulk_user_updater_"+ temporaryId +"_birthday"){
                  dataOrder = birthday;
                } else if (attrId === "bulk_user_updater_"+ temporaryId +"_start_date"){
                  dataOrder = startDate;
                }
                $parentTd.attr("data-order", dataOrder);
              }
            });

            var cellHTMLStr = $cellEl.html().replace(new RegExp(temporaryId, 'g'), actualId);
            cellHTMLStr = cellHTMLStr.replace(new RegExp('create', 'g'), 'update');
            table.cell(this).data(cellHTMLStr);
          });
          $row.attr("id", "user-row-" + actualId);

          // set new row column value to false, post user creation
          $row.find('td.is_new_row').html(0);
        });
        that.setDatePicker();
      }

      if (numAccountsUpdated > 0) {
        $.each(successObj.data.bulk_user_updater.updated_users, function() {
          var $row = $("#user-row-" + this.id);

          var userId = this.id;
          delete this.id;
          delete this.network;

          $.each(this, function(key, value){
            var attrId = "#bulk_user_updater_" + userId +"_"+ key;
            var $inputEl = $row.find(attrId);
            $inputEl.parent("td").attr("data-order", value);
          });
        });
      }

      /**
        need to reset datatable cache for sorting to work for the updated cells
        source: https://datatables.net/reference/api/row().invalidate()
      **/

      table.rows().invalidate('dom').draw();

      if (numAccountsCreated === 0 && numAccountsUpdated === 0) {
        msg = "No accounts were modified";
      } else if (numAccountsCreated > 0 && numAccountsUpdated > 0) {
        msg = numAccountsCreated + " accounts created, and " + numAccountsUpdated + " accounts updated";
      } else if (numAccountsCreated > 0) {
        msg = numAccountsCreated + " accounts created";
      } else {
        msg = numAccountsUpdated + " accounts updated";
      }

      successFeedback(msg, $("#edit-accounts #response-feedback-wrapper"));
    });
  };

  Accounts.prototype.bindAccountsError = function() {
    $window.bind('ajaxify:errors:edit_bulk_user_updater', function(e, successObj) {
      $("#edit-accounts table").dataTable().fnSort([2, 'desc']);
    });
  };

  Accounts.prototype.bindAccountsFormChangeHandler = function() {
    $document.on("change", "input[type=checkbox]", function() {
      $(this).parents("tr").removeClass("selected");
    });

    $("#edit-accounts").on("change keyup", "input:not([type=checkbox]), select", function() {
      var $row = $(this).parents("tr");
      $row.addClass("selected");
      $row.find("input[type=checkbox]").attr('checked', true);
    });
  };

  Accounts.prototype.bindAddAccountBtn = function() {
    var that = this;
    $document.on('click', "#add-account", function() {
      var $addBtn = $(this);
      var time = new Date().getTime();

      var id = $addBtn.data('id');
      var template = $addBtn.data('newAccountTemplate');

      var regexp = new RegExp(id, 'g');

      var table = $("#edit-accounts table").dataTable();
      var rowHtml = template.replace(regexp, time);
      rowHtml = rowHtml.replace(/SK\-.*\-SK/, "_SK-" + time + "-SK");

      table.api().row.add($(rowHtml)[0]).draw();
      that.setDatePicker();
    });
  };

    // Note: Before colvis was implemented, updating DOM elements of the affected row would be tackled by just replacing
    // the overall row with 'user_set_row' template or by changing the html of the affected td cells that required updating
    // However, after implementation of colvis, an affected column might not necessarily be present in the DOM if the
  // relevant column is hidden, making the update rather impossible. Therefore, instead of manipulating the DOM, to
  // handle the dynamism of colvis, we update the relevant row's data.
  Accounts.prototype.updateUserRow = function(rowSelector, updatedUserRowData) {
    this.accountsDataTable.row(rowSelector).data(updatedUserRowData);
    this.reinitializeRowComponents(rowSelector);
  };

    // Used by 'activate' and 'destroy' actions
  Accounts.prototype.reinitializeRowComponents = function(row) {
    var $row = row instanceof $ ? row : $(row);
    var $companyRoleSelect = $row.find("select.user-company-role-select");
    var $teamSelect = $row.find("select.user-team-select");
    var $managerSelect = $row.find("select.manager-select");
    this.initializeRolesSelect2($companyRoleSelect);
    this.initializeTeamsSelect2($teamSelect);
    this.bindManagerAutocomplete($managerSelect);
  };

  Accounts.prototype.bindRolesSelect = function($target) {
    new window.R.Select2(function () {
      Accounts.prototype.initializeRolesSelect2();

      if (!Accounts.prototype.bindRolesSelect.loadedEvents) {
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

        Accounts.prototype.bindRolesSelect.loadedEvents = true;
      }
    });
  };


  function DynamicUserTeamCreator(){

    this.createUserTeam = function(endpoint, ajaxData, $selectElement, isNewTeam) {
      var $triggererSelect = $selectElement;

      var that = this;

      $.ajax({
        url: endpoint,
        data: ajaxData,
        method: "post"
      }).done(function(data) {
        that._handleSuccessfulUserTeamCreation($triggererSelect, isNewTeam, data.team);
      }).fail(function(data) {
        that._showError(data);
      }).always(function(data){
        that._removeTag($triggererSelect);
      });
    };

    this.createNewTeamTag = function(params) {
      var term = $.trim(params.term);

      if (term === '') {
        return null;
      }

      return {
        id: term,
        name: term,
        text: term,
        newTag: true
      };
    };

    this.formatNewTeamTag = function(team) {
      if(team.newTag) {
        var createNewTeamHint = "Create new team: ";
        if (team.text.indexOf(createNewTeamHint) === -1) {
          team.text = createNewTeamHint + team.text;
        }
      }

      return team.text;
    };

    this._showError = function(data){
      var errorMessage = 'Sorry, something went wrong. Please try again later.';
      if (data.status === 422 && data.responseJSON) {
        var errors = data.responseJSON.errors;
        errorMessage = new window.R.forms.Errors(null, errors).getErrorMessagesFromErrorsObject().join("<br>");
      }
      Swal.fire('Team creation failed!', errorMessage, 'error');
    };

    this._removeTag = function($triggererSelect) {
      // Remove the user entered new option regardless of whether the ajax succceed or failed. Its obvious that when its
      // a fail'ed case, the option must be removed. And, for success, since we insert a new option for team that is
      // returned from the server after creation in the concerned select, we remove the user entered one.
      $triggererSelect.find("option[data-select2-tag=true]").remove();
      $triggererSelect.trigger('change');
    };

    this._handleSuccessfulUserTeamCreation = function($triggererSelect, isNewTeam, team){
      if (isNewTeam){
        var teamOptionUnselected = new Option(team.label, team.id, false, false);
        var teamOptionSelected = new Option(team.label, team.id, false, true);

        $triggererSelect.append(teamOptionSelected).trigger('change');
        // Add the newly added team to all team selects in the current view.
        var $selectsOtherThanTriggererSelect = $(".user-team-select").not($triggererSelect);
        $selectsOtherThanTriggererSelect.append(teamOptionUnselected).trigger('change');
      }
    };
  }

  Accounts.prototype.bindTeamsSelect = function() {
    new window.R.Select2(function() {
      this.initializeTeamsSelect2();

      var that = this;

      if (!this.bindTeamsSelect.loadedEvents) {
        $document.on('select2:select', '.user-team-select', function(event) {
          var data = { team_id: event.params.data.id };
          var isNewTeam = event.params.data.newTag === true;
          if(isNewTeam) {
            // For newTags, select2 relies on the new option's `id` to be present, which it sets to be the inputted term.
            // However, at this point in execution, we don't need it, therefore it is null-ified to prepare request data.
            // For more, see:  https://select2.org/tagging#tag-properties
            data.team_id = null;
            data.team_name = event.params.data.name;
          }
          that.dynamicUserTeamCreator.createUserTeam($(this).data("url"), data,  $(this), isNewTeam);
        });

        $document.on('select2:unselect', '.user-team-select', function(event) {
          $.ajax({
            url: $(this).data("url"),
            data: { team_id: event.params.data.id, _method: "delete" },
            type: "post"
          });
        });

        this.bindTeamsSelect.loadedEvents = true;
      }
    }.bind(this));
  };

  Accounts.prototype.bindManagerAutocomplete = function($target) {
    new window.R.Select2(function () {
      var url = "/coworkers";
      var dept = window.R.utils.queryParams().dept;
      if (dept) {
        url = url + "?dept=" + dept;
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
        allowClear: true,
        minimumInputLength: 1,
        placeholder: '',
        templateResult: formatUser,
        templateSelection: formatUserSelection
      });
    });

  };
  Accounts.prototype.bindManagerSelect = function() {
    if (!Accounts.prototype.bindManagerSelect.loadedEvents) {
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
      Accounts.prototype.bindManagerSelect.loadedEvents = true;
    }
  };

  Accounts.prototype.initializeRolesSelect2 = function($target) {
    if ($target === undefined) {
      $target = $(".user-company-role-select");
    }
    $($target.selector + ':not(.select2-hidden-accessible)').select2({
      tokenSeparators: [',', ' ']
    });
  };

  Accounts.prototype.initializeTeamsSelect2 = function($target) {
    var that = this;
    if ($target === undefined) {
      $target = $(".user-team-select");
    }
    $($target.selector + ':not(.select2-hidden-accessible)').select2({
      tokenSeparators: [','],
      tags: true,
      createTag: that.dynamicUserTeamCreator.createNewTeamTag,
      templateResult: that.dynamicUserTeamCreator.formatNewTeamTag
    });
  };

  Accounts.prototype.bindShowForgottenPasswordLink = function() {
    $document.on('click', '#show-forgotten-password-link', function(event){
      event.preventDefault();

      var target = $(event.target);
      var network = target.data('network');
      var user_id = target.data('user-id');
      var user_name = target.data('user-name');

      $.ajax({
          method: 'GET',
          url: '/' + network + '/company/accounts/user_password_reset_link',
          data: {
              user: {
                  id: user_id
              }
          },
          success: function (response) {
              Swal.fire({
                  title: 'Reset Password Link for ' + user_name,
                  html: '<pre>' + response['password_reset_url'] + "</pre><br><p class='subtle-text small-text'>A user who has not set a password will receive an invite and those who have will receive a password reset url. Password reset urls will expire in 10 minutes.</p>"
              });
        }
      });
    });
  };

  Accounts.prototype.bindResetPasswordLink = function() {
    $document.on('click', '#reset-password-link', function(event){
      event.preventDefault();

      var target = $(event.target);
      var user_name = target.data('user-name');
      var user_id = target.data('user-id');
      var network = target.data('network');

        var form = '<label style="text-align:left;">New Password </label><input type="password" id="new-password" name="new-password" style="width:100%;" />';

      Swal.fire({
          title: 'Reset password for ' + user_name,
          html: form,
          showCancelButton: true,
          confirmButtonText: "Reset Password",
          showLoaderOnConfirm: true,
          preConfirm: function () {
              return new Promise(function (resolve, reject) {
                  var new_password = $('[name=new-password]').val();

                  $.ajax({
                      method: 'PATCH',
                      url: '/' + network + '/company/accounts/update_user_password',
                      data: {
                          user: {
                              id: user_id,
                              password: new_password
                          }
                      },
                      success: function () {
                          resolve();
                      },
                      error: function (err) {
                reject(err);
              }
            });
          }).then(function() {
                  Swal.close();
                  Swal.fire('Success', 'Password for ' + user_name + ' has been updated.', 'success');
          }).catch(function(err) {
            Swal.showValidationMessage('Password ' + err.responseJSON['errors']['password']);
          });
        },
      });
    });
  };

  Accounts.prototype.bindInviteFormSendTypeSelect = function() {
    var type_select = $('#new_bulk_mailer_form #send-type-select');
    type_select.find('input[type=checkbox]').change(function(event) {
      var target = $(event.target);
      var controls = $('#' + target.prop('name') + '-controls');
      var disable = true;

      if (target.prop('checked')) {
        disable = false;
        controls.show(200);
      } else {
        type_select.find('input[type=checkbox]').each(function() {
          if( $(this).prop('checked') ) {
            disable = false; // If any boxes are checked, do not disable.
          }
        });
        controls.hide(200);
      }

      $('.swal2-actions .swal2-confirm').prop('disabled', disable);
    });
  }

  Accounts.prototype.bindInviteFormGroupSelect = function() {
    $('#bulk-mail-group-select a').click(function(event){
      var target = $(event.target);
      var role = target.data('role');
      $('#bulk_mailer_form_group').val(role);
    });
  }

  Accounts.prototype.bindInviteFormControls = function() {
    $("#new_bulk_mailer_form select").select2();
    this.bindInviteFormSendTypeSelect();
    this.bindInviteFormGroupSelect();
  };

  Accounts.prototype.bindInviteEmailerButton = function() {
    var self = this;

    $document.on('click', '#invite-accounts', function(){
      var form = $(this).data('form');
      Swal.fire({
        title: 'Broadcast to Staff',
        html: form,
        showCancelButton: false,
        confirmButtonText: "Broadcast",
        showLoaderOnConfirm: true,
        preConfirm: function(){
          return new Promise(function(resolve, reject) {
            var og_form = $("#new_bulk_mailer_form");

            if( !$('#send-type-select [name=bulk-email]').is(':checked') ) {
              // Detach email controls if sending emails is not specified, so value is not passed to controller.
              $('#bulk-email-controls').detach();
            }

            if( !$('#send-type-select [name=bulk-sms]').is(':checked') ) {
              // Similar as above, except with sms controls.
              $('#bulk-sms-controls').detach();
            }

            if($("#bulk_mailer_form_group_by_role").is(":checked") &&
               $("#bulk_mailer_form_roles_ :selected").length === 0) {
              var result = confirm('This will send to everyone who doesn\'t have a role. Is this what you intended?');
              if(result) {
                submitBulkEmailForm(resolve, reject, og_form);
              } else {
                reject();
              }
            } else {
              submitBulkEmailForm(resolve, reject, og_form);
            }
          }).catch(function (reason) {
            // this prevents the modal from closing when there is an error (eg. validation errors)
            Swal.showValidationMessage(reason);
          });
        },
        onOpen: function() {
          self.bindInviteFormControls();
        }
      });
    });

    function submitBulkEmailForm(resolve, reject, form) {
      form.on("ajax:success", function(){
        Swal.fire('Success', 'Your messages have been scheduled for delivery.', 'success');
      }).on("ajax:error", function(_event, request){
        var message = (request.status === 422) ?
                      'We could not send the emails to your users. Please see above.' : // validation error
                      'Sorry, something went wrong. Please contact support.'; // server error (unusual)
        reject(message);
      }).submit();
    }

    $document.on('click', '#new_bulk_mailer_form .button-group .button', function() {
      var $this = $(this);
      $('#new_bulk_mailer_form .button-group .button').removeClass('active');
      $this.addClass('active');

      $(".bulk-mail-detail").hide();
      var showDiv = $("#"+$this.attr('id')+'-detail');
      showDiv.show();
    });

    $document.on('click', '#template-tags .badge', function(){
      var url = $(this).data('url');
      $("#bulk_mailer_form_body").val($("#bulk_mailer_form_body").val() + "\n"+url);
    });

    $document.on('click', '#sms-template-tags .badge', function(){
      var url = $(this).data('url');
      $("#bulk_mailer_form_sms_body").val($("#bulk_mailer_form_sms_body").val() + "\n"+url);
    });
  };

  Accounts.prototype.setDatePicker = function() {
    var that = this;
    new window.R.DatePicker(function(){
      $(".datepicker:not(.noYear) input").datepicker({
        format: "mm/dd/yyyy",
        autoclose: true
      });

      $(".datepicker.noYear input").datepicker({
        format: "mm/dd",
        viewMode: "months",
        autoclose: true
      });
      // this has to come after datepicker is setup
      // otherwise, it seems, adding datepicker,
      // triggers change handler causing change events to
      // fire that we don't want to yet
      that.bindAccountsFormChangeHandler();
    });
  };

  function successFeedback(message, element) {
    var $existingButtons = element.find(".success-mention");
    $existingButtons.remove();
    var $successButton = $('<p class="success-mention success-text">' + message + '</p>');
    element.append($successButton);
    $successButton.fadeOut(4000);
  }

  return Accounts;

})();
