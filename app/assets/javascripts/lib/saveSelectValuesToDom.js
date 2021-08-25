
/*
 * Saves updated select values to DOM (in original <option> elements) so that they are preserved on Turbolinks restore
 * This works for both select2 as well as plain selects (since the underlying <select> element is synced anyway)
 * @see issue #1450 / PR 1443
 *
 * Note: This is not needed for most selects (depends upon form & page restore behavior)
 * For eg.
 *   Some views (like Datatables) are fully reloaded on page restore
 *   Many forms (like Custom badges page) do not save changes until submitted, which will refresh the page anyway
 *   Some selects (like Custom date range) reload the page on change
 **/

window.R = window.R || {};
window.R.utils = window.R.utils || {};

window.R.utils.saveSelectValuesToDom = function(wrapperSel) {
  $(wrapperSel + ' select').each(function (_index, select) {
    var $select = $(select);
    var selected = $select.val();

    if (!selected) return; // skip if select value is empty

    var $options = $select.children('option');
    $options.attr('selected', null); // reset all options first

    var $selectedOptions;
    if ($.isArray(selected)) { // multiple select2
      $selectedOptions = $options.filter(function () {
        return selected.indexOf(this.value) !== -1;
      });
    } else { // plain select or single select2
      $selectedOptions = $options.filter(function () {
        return this.value === selected;
      }).eq(0);
    }

    if ($selectedOptions) {
      $selectedOptions.attr('selected', true);
    }
  });
};

