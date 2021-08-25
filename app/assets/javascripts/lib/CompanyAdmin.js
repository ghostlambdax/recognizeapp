window.R = window.R || {};

window.R.CompanyAdmin = (function($, window, body, R, undefined) {
  'use strict';

  var CompanyAdmin = function() {
    this.addEvents();
  };
    
  CompanyAdmin.prototype.addEvents = function() {
    this.autoSaver = new R.AutoSaver();
    this.setupDeptSelect();
    $document.bind("turbolinks:request-start", this.removeEvents.bind(this));

    // a bit hacky, but simple for now so we can ship code
    // old company admin uses #company-admin-content-wrapper
    // new company admin uses #company-admin-wrapper
    if ($("#company-admin-content-wrapper.paid").length === 0 && $(".company-admin-wrapper.paid").length === 0) {
      this.lockUnpaidCompanyAdmin();
      return;
    }    
  };

  CompanyAdmin.prototype.setupDeptSelect = function() {
    new window.R.Select2(this.bindMenuDeptSelect);
  };

  CompanyAdmin.prototype.bindMenuDeptSelect = function() {
    var $select = $('#dept-select').select2();
    $select.on('select2:select', function() {
      var $this = $(this),
        queryObj,
        url;

      queryObj = window.R.utils.queryParams();
      queryObj[$this.prop('name')] = $this.val();
      var queryParams = $.param(queryObj);

      url = window.location.pathname + "?" + queryParams;

      if (window.location.hash !== "") {
        url += window.location.hash;
      }

      window.location = url;

    });

  };

  CompanyAdmin.prototype.removeEvents = function() {
    $window.unbind("ajaxify:success:comment_add", this.add);
  };
  
  CompanyAdmin.prototype.lockUnpaidCompanyAdmin = function() {
    this.$companyWrapper = $(".company-admin-wrapper");
    var $selects;

    $(".iOSCheckContainer").off('mousedown mousemove touchstart click');

    this.$companyWrapper.on('change mousedown touchstart click', '.iOSCheckContainer, input[type=checkbox], input[type=file]', function(e) {
      promptToPay(e);
      return false;
    });

    this.$companyWrapper.on('click', 'a:not(.unlocked):not(#upgrade-link),button,input[type=submit]:not(.unlocked)', function(e) {
      promptToPay(e);
      return false;
    });

    $("#company-admin-content-wrapper select").focus(function() {
      $(this).data('lastSelected', $(this).find('option:selected'));
    });

    $selects = $('#company-admin-content-wrapper select');
    $selects.change(function(e) {
      $(this).data('lastSelected').attr('selected', true);
      promptToPay(e);
      return false;
    });
  };  

  function promptToPay(e) {
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();

    Swal.fire({
        imageUrl: "/assets/badges/100/powerful.png",
        title: "Engage your staff",
        // text: "By upgrading to a paid package of Recognize, you can maximize its success through customizations and integration. Upgrade to start your movement. If you have any questions, <a href='/contact'>contact us</a>",
        text: 'Successful companies using Recognize customized their badges and more. Upgrade to start customizing.',
        showCancelButton: true,
        confirmButtonColor: "#5cc314",
        cancelButtonText: "I'll think about it",
        confirmButtonText: "Upgrade",
        animation: "slide-from-top"
    }).then(function(result) {
      if (result.value) {
        window.location = '/welcome/?upgrade=true';
      }
    });

  }

  CompanyAdmin.prototype.autosaveSetting = function(settingSelector, done, fail, always, abort) {
    this.autoSaver.autoSave(settingSelector, done, fail, always, abort);
  };

  return CompanyAdmin;
  
})(jQuery, window, document.body, window.R);