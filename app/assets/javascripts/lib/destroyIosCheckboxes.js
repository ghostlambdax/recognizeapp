window.R = window.R || {};
window.R.utils = window.R.utils || {};

/**
 * Destroys IOS Checkbox element, leaving the input in initial state so that it can be re-initialized on page restore
 * Note: This sometimes causes the raw checkboxes to be displayed temporarily when the cached page is shown during fetch
 *
 * The relevant library `ios-checkboxes` doesn't have a destroy method. This is a custom implementation.
 */

window.R.utils.destroyIOSCheckboxes = function(wrapper) {
  var $inputs = $(wrapper).find('.iOSCheckContainer > input.on-off');
  $inputs.each(function (_index, input) {
    var $input = $(input);
    $input.siblings().remove();
    $input.unwrap();
  });
};