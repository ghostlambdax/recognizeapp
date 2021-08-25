function rLog(label, value) {
  'use strict';
  if(window.localStorage && window.localStorage.rLog) {
    var signature = [];

    label = '__' + label + '__';

    if (value) {
      console.log(label, value);
    } else {
      console.log(label);
    }
  }
}
