window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_recognitions-index"] = (function() {
  'use strict';
  var tableId = '#recognitions-table';

  var Re = function() {
    this.$table = $(tableId);
    $("#recognitions-table").on('draw.dt', function(){
      this.addEvents();
    }.bind(this));
  };

  Re.prototype.addEvents = function() {
    var that = this;

    new R.CompanyAdmin();
    this.addSwalEvents();
    window.R.QuickNominations();

    // add select2 to filters
    new window.R.Select2(function(){
      $("#recognitions-filter-wrapper .select2").select2();
    });
    // END - FIXME: obsolete code
  };

  // Note: this method is used by Litatable.js
  Re.prototype.renderGroupRow = function (rowGroup, rows, group) {
    // datatable.data.options.rowGroup.startRender = renderRowGroup;
    var totalColumns = rowGroup.s.dt.columns()[0].length;
    var rowsData = rows.data().reduce(function(a,b){a.push(b);return a}, [])
    var actions = rowsData[0].actions; // same for all rows in group
    if(actions) {
      return  $('<tr/>').prop('id', group)
        .append('<td colspan='+totalColumns+'>' +
                  '<p>'+group+'</p>' +
                  '<div id="recognition-actions-'+group+'">'+actions+'</div>' +
                ' </td>');
    } else {
      return $('<tr/>').prop('id', group)
        .append('<td colspan='+totalColumns+'>' +
                  '<p id="'+group+'">'+group+'</p>' +
                '</td> ');
    }
  };

  Re.prototype.removeEvents = function() {};

  Re.prototype.addSwalEvents = function() {
    $body.on(R.touchEvent, ".approve-button", this.approveButton.bind(this));
    $body.on(R.touchEvent, ".deny-button", this.denyButton.bind(this));
  };

  Re.prototype.approveButton = function(e) {
    e.preventDefault();
    this.verifyApprovePopup(e.target, "Approve recognition?", 'Please confirm recognition message and points.');
  };

  Re.prototype.verifyApprovePopup = function(el, title, description) {
    var $this = $(el);

    var swalOpts = getGenericSwalOptsForApprovalWorkflow(title, description, 'Approve', 'recognition-approval-swal', submitApprovalForm.bind(el))
    var pointValues = $this.data("pointValues");

    var recognitionMessage = $this.data("message") || '';
    swalOpts.html += formatSwalInputGroupForRecognitionAttributes($this.data());
    swalOpts.html += formatSwalInputGroupForRecognitionMessage(recognitionMessage);

    if (pointValues && pointValues.length) {
      var pointValuesMap = arrayToHash(pointValues);
      var inputFieldOpts = {
        input: "select",
        inputOptions: pointValuesMap,
        inputAttributes: { name: 'points' },
        onOpen: function (modalEl) {
          $(modalEl).find('select[name="points"]').select2();
        }
      };
      $.extend(swalOpts, inputFieldOpts);

      var pointValueLabel = 'Recognition Points:';
      swalOpts.html += '<label class="points-label">' + pointValueLabel + '</label>';
    }

    var inputFormat = $this.data('inputFormat');
    // this field is mutated when the wysiwyg editor is initialized
    swalOpts.html += '<input name="input_format" type="hidden" value="' + inputFormat + '"/>';

    var wysiwygEditorInitialized;
    var callbackOpts = {
      onOpen: function(modalEl) {
        var $modalEl = $(modalEl);
        if (pointValues && pointValues.length) {
          $modalEl.find('select[name="points"]').select2();
        }
        if (gon.recognition_wysiwyg_editor_enabled || inputFormat === 'html') {
          var $message = $modalEl.find('#message');
          var inputFormatOpts = {
            $elem: $modalEl.find('input[name="input_format"]'),
            currentFormat: inputFormat
          };

          R.ui.initWYSIWYG($message, inputFormatOpts);
          wysiwygEditorInitialized = true;
        }
      },
      onClose: function (modalEl) {
        if (wysiwygEditorInitialized) {
          R.ui.destroyWYSIWYG($(modalEl).find('#message'));
        }
      }
    };
    $.extend(swalOpts, callbackOpts);

    Swal.fire(swalOpts).then(function(result) {
      if (result.value !== undefined) {
        var $prc = $("#pending-recognition-count");
        $prc.text(parseInt($prc.text()) - 1);
        Swal.fire('Recognition Approved!', 'Recognition has been successfully approved.', 'success');
      }
    });
  };

  function submitApprovalForm() {
    return new Promise(function(resolve, reject) {
      var $swalContainer = $('.swal2-container');
      var ajaxData = {
        message: $swalContainer.find('textarea[name="message"]').val(),
        points: $swalContainer.find('select[name="points"]').val(), // ignored when input is absent
        input_format: $swalContainer.find('input[name="input_format"]').val(),
        request_form_id: $(this).data('request-form-id')
      };

      postToEndpointAndSettlePromise(this, ajaxData, resolve, reject);
    }.bind(this)).catch(function (reason) {
      // this prevents the modal from closing when there is an error (eg. validation errors)
      Swal.showValidationMessage(reason);
    });
  }

  function formatSwalInputGroupForRecognitionAttributes(data, includeMessage) {
    if (typeof includeMessage === "undefined") includeMessage = false;

    var sender = '<div><span>Sender: </span>' +
             '<span>' + data.sender + '</span></div>';

    var recipients = '<div><span>Recipients: </span>' +
             '<span>' + data.recipients + '</span></div>';

    var badge = '<div><span>Badge: </span>' +
             '<span><img src="' + data.badgeImage + '" height="21px"/></span>' +
             '<span> ' + data.badgeName + '</span></div>';

    if(includeMessage) {
      var message = '<div><span>Message: </span>' +
             '<div class="message">"' + (data.message || '') + '"</div></div>';
    } else {
      message = '';
    }

    var str = '<div class="recognition-attributes-wrapper well width100">' +
              sender + recipients + badge + message +
             '</div>';
     return str;
  }
  function formatSwalInputGroupForRecognitionMessage(message) {
    var label = "Recognition Message:";
    return '<div class="message-wrapper">' +
             '<label>' + label + '</label>' +
             '<textarea id="message" name="message">' + message + '</textarea>' +
           '</div>';
  }

  function arrayToHash(arr) {
    return arr.reduce(function(map, val){
      map[val] = val;
      return map;
    }, {});
  }

  Re.prototype.denyButton = function(e) {
    e.preventDefault();
    this.verifyDenyPopup(e.target, "Deny recognition?", "Double checking you want to deny this recognition.");
  };

  Re.prototype.verifyDenyPopup = function(el, title, description) {
    var $this = $(el);

    var swalOpts = getGenericSwalOptsForApprovalWorkflow(title, description, 'Deny', 'recognition-denial-swal', submitDenialForm.bind(el))

    swalOpts.html += formatSwalInputGroupForRecognitionAttributes($this.data(), true);

    var inputAttributes = {
      input: 'text',
      inputPlaceholder: 'Reason for denial',
      inputAttributes:  {name: 'denial_message'}
    };
    $.extend(swalOpts, inputAttributes);

    Swal.fire(swalOpts).then(function(result) {
      if (result.value !== undefined) {
        var $prc = $("#pending-recognition-count");
        $prc.text(parseInt($prc.text()) - 1);
        Swal.fire('Recognition Denied!', 'Recognition has been successfully denied.', 'success');
      }
    });
  };

  function submitDenialForm() {
    return new Promise(function(resolve, reject) {
      var $swalContainer = $('.swal2-container');
      var ajaxData = {
        denial_message: $swalContainer.find('input[name="denial_message"]').val()
      };

      postToEndpointAndSettlePromise(this, ajaxData, resolve, reject);
    }.bind(this)).catch(function (reason) {
      // this prevents the modal from closing when there is an error (eg. validation errors)
      Swal.showValidationMessage(reason);
    });
  }

  function postToEndpointAndSettlePromise(element, ajaxData, resolve, reject) {
    var defaultAjaxData = {_method: 'put'};
    var data = $.extend({}, defaultAjaxData, ajaxData);

    $.ajax({
      url: $(element).data('endpoint'),
      type: 'post',
      data: data
    }).then(
      function success(response) { resolve() },
      function failure(error) {
        var errorMessage = 'Sorry, something went wrong. Please try again later.';

        if (error.status === 422 && error.responseJSON) {
          var errors = error.responseJSON.errors;
          errorMessage = new window.R.forms.Errors(null, errors).getErrorMessagesFromErrorsObject().join("<br>");
        }
        reject(errorMessage);
      }
    );
  }

  function getGenericSwalOptsForApprovalWorkflow(title, description, confirmBtnText, customClass, preConfirmFn) {
    return {
      icon: "warning",
      title: title,
      html: description,
      showCancelButton: true,
      showLoaderOnConfirm: true,
      confirmButtonText: confirmBtnText,
      customClass: customClass,
      preConfirm: preConfirmFn,
      allowOutsideClick: function () {
        return !Swal.isLoading();
      }
    };
  }

  return Re;

})();
