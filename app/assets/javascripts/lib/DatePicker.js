window.R = window.R || {};

window.R.DatePicker = function(callback) {
  'use strict';

  //console.log('DatePicker constructor');
  if (typeof ($.fn.datepicker) === 'function') {
    //console.log('DatePicker is loaded');
    callback();
  } else {
    //console.log('DatePicker is NOT loaded');
    $('head').append($('<link rel="stylesheet" type="text/css" />').attr('href', 'https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datepicker/1.9.0/css/bootstrap-datepicker.min.css'));
    $.getScript('https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datepicker/1.9.0/js/bootstrap-datepicker.min.js', function () {
      var languageScript;
      var lang = $('html').attr('lang');

      moment.tz.setDefault("America/Los_Angeles");

      if (lang === undefined || lang === 'en') {
        callback();
      } else {
        languageScript = document.createElement('script');
        languageScript.onerror = callback;
        languageScript.onload = callback;
        languageScript.src = 'https://cdnjs.cloudflare.com/ajax/libs/bootstrap-datepicker/1.9.0/locales/bootstrap-datepicker.' + lang + '.min.js';
        document.body.appendChild(languageScript);
      }

    });
  }
};
