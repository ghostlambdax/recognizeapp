(function () {
  window.R = window.R || {};
  window.R.SwalForm = SwalForm;

  function SwalForm() {
    this.addEvents();
  }

  SwalForm.prototype.addEvents = function () {
    $document.on(R.touchEvent, '.swal-form-link', function(evt) { 
      this.showSwalForm(evt) 
    }.bind(this));
  };

  SwalForm.prototype.removeEvents = function () {
    $document.off('click', '.swal-form-link');
  };

  SwalForm.prototype.showSwalForm = function(evt) {
    var $swalLink = $(evt.target);
    var swalFormId = $swalLink.data('swalform-id');
    var $swalForm = $("#"+swalFormId);
    var successMessage = $swalLink.data('swalform-successmessage');
    var reshowForm = $swalLink.data('swalform-reshowform') || false;
    var that = this;

    Swal.fire({
      icon: $swalLink.data('swalform-icon') || 'info',
      title: $swalLink.data('swalform-title') || null,
      confirmButtonText: $swalLink.data('swalform-confirmbuttontext') || 'Save',
      html: $swalForm[0].outerHTML,
      focusConfirm: $swalLink.data('swalform-focusconfirm') || true,
      showCancelButton: $swalLink.data('swalform-showcancelbutton') || true,
      reverseButtons: $swalLink.data('swalform-reversebuttons') || true,
      showLoaderOnConfirm: $swalLink.data('swalform-showloaderonconfirm') || true,
      onOpen: function(el){
        // assume selects with .select2 want to be select2()'d.
        // when the swal is opened
        $(".swal2-container select.select2").select2();

        // For now, just implement preloading the data once
        $(".swal2-container select.select2-remote").each(function(){
          var $el = $(this);
          var endpoint = $el.data('endpoint');
          $.ajax({
            url: endpoint,
            dataType: 'json'
          }).then(function(data){
            $el.select2({ data: data.results });
          });
        });
      },
      preConfirm: function () {
        return new Promise(function (resolve, reject) {

          $.ajax({
            method: $swalForm.find("input[name=_method]").prop("value") || $swalForm.prop('method'),
            url: $swalForm.prop('action'),
            data: $(".swal2-content form").serialize(),
            dataType: 'script',
            success: function () {
              resolve();
            },
            error: function (err) {
              reject(err);
            }
          });
        }).then(function () {
          Swal.close();
          Swal.fire('Success', successMessage || 'Changes have been saved', 'success').then(function(){
            if(reshowForm) {
              that.showSwalForm(evt);
            }
          });
        }).catch(function (err) {
          try{
            var responseErrors = JSON.parse(err.responseText)['errors'];
            var errors = new window.R.forms.Errors($(".swal2-content form"), responseErrors);
            errors.renderErrors();
            Swal.showValidationMessage('The form could not be saved');
          } catch(e) {
            console.log(e)
            Swal.showValidationMessage('We\'re sorry. The form could not be saved. <br />Please try again. If this continues, please contact support@recognizeapp.com.');
          }
        });
      }

    });

  }

})();
