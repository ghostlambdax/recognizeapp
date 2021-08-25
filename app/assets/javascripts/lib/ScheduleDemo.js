window.R = window.R || {};
window.R.ui = window.R.ui || {};

window.R.ui.ScheduleDemo = (function($, window, undefined) {
    'use strict';

    var LINK_CLASS = ".schedule-demo";
    var SMALL_COMPANY_THRESHOLD = 50;

    var SD = function() {
        if ( $(LINK_CLASS).length ) {
            this.addEvents();
        }
    };

    SD.prototype.companySizeFactory = function(result) {
        if (result.value) {
            var $numberUsers = $("#numberUsers");

            if ( isNaN( parseInt($numberUsers.prop('value')) ) ) {
                return false;
            }

            if ($numberUsers.prop('value') > SMALL_COMPANY_THRESHOLD) {
              this.largeCompanyAlert($numberUsers.prop('value'));
            } else {
                smallCompanyAlert();
            }

        }
    };

    SD.prototype.largeCompanyAlert = function(size) {
      this.iFrameURL = size > 200 ? 'https://davidjones-recognize.youcanbook.me' : 'https://recognize-sales.youcanbook.me';
      this.iFrameURL += ( '?' + this.$targetElement.data('attr') );
      this.iFrameURL += '&COUNT=' + size;

      Swal.fire({
          html: '<img src="/assets/icons/ajax-loader-medium.gif" id="scheduleDemoiFrameLoader"><iframe class="scheduleDemoiFrame" src="'+this.iFrameURL+'" style="width: '+($window.outerWidth()-100)+'px; height: '+($window.outerHeight()-100)+'px;" onload="document.getElementById(\'scheduleDemoiFrameLoader\').style.display=\'none\';"></iframe>',
          grow: 'fullscreen',
          showCloseButton: true,
          showCancelButton: false,
          showConfirmButton: false
      });
    };

    function smallCompanyAlert() {
        Swal.fire({
            icon: 'question',
            iconHtml: '<i data-feather="users"></i>',
            title: 'Small Companies or Teams',
            html: '<p><strong>Sign up for free</strong> and upgrade whenever you are ready. Comes with a 30 day money back guarantee.</p>',
            footer: '<i data-feather="youtube" height="20" color="#87adbd" style="margin-right: 5px;"></i><p class="subtle-text">Not ready to sign up? The <a href="/videos">video demos</a> show the product and more.</p>',
            confirmButtonText: 'Sign Up',
            showCloseButton: true
        }).then(function(result) {
            if (result.value) {
                Turbolinks.visit('/sign-up');
            }
        });

        feather.replace();
    }

    SD.prototype.setupButton = function(e) {
        e.preventDefault();
        this.$targetElement = $(e.target);
        this.iFrameURL = this.$targetElement.prop('href');
        this.openUserCountAlert();
        return false;
    };

    SD.prototype.userCountHTML = "<div class='demo-user-count'>" +
                                    "<label>" +
                                      "<h3>How many employees do you have?</h3>" +
                                      "<input type='number' value=500 id='numberUsers' min=1 class='user-count-input'>" +
                                    "</label>" +
                                  "</div>";

    SD.prototype.openUserCountAlert = function() {
        var firstAlert = Swal.fire({
            title: '<strong>Scheduling a Demo</strong>',
            html: this.userCountHTML,
            showCloseButton: true,
            icon: 'question',
            iconHtml: '<i data-feather="calendar"></i>',
            showCancelButton: false,
            focusConfirm: false,
            confirmButtonText:
                'Submit',
            confirmButtonAriaLabel: 'Submit',
            cancelButtonAriaLabel: 'Cancel'
        });

        firstAlert.then(this.companySizeFactory.bind(this));
        feather.replace();
    };

    SD.prototype.addEvents = function() {
        $document.on('keyup', '#numberUsers', function(e) {
            if (e.keyCode === 13) {
                this.companySizeFactory({
                    value: $(e.target).prop("value")
                });
            }
        }.bind(this));

        $document.on(R.touchEvent, LINK_CLASS, this.setupButton.bind(this));
    };

    return SD;
})(jQuery, window);
