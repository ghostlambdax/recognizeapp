window.R.pages["users-index"] = (function($, window, body, R, undefined) {
  var T = function() {
    this.$table = $('#users-table');
    this.parentRowExpandedClass = 'expanded';
    this.childRowDisplayedClass = 'shown';
    this.childContainerKey = 'child-container';
    this.parentRowKey = 'parent-row';
    this.DRToggleLinkSelector = '.toggle_dr';

    this.addEvents();
  };

  T.prototype.addEvents = function() {
    this.bindDirectReportsToggleLink();
    this.bindCollapseBar();
  };

  T.prototype.bindDirectReportsToggleLink = function() {
    var that = this;
    this.$table.on(R.touchEvent, that.DRToggleLinkSelector, function (e) {
      e.preventDefault();
      var $link = $(e.target);
      var $tr = $link.closest('tr');

      var $child = $tr.data(that.childContainerKey);
      if ($child) {
        // child row has already been loaded previously, just toggle
        that.toggleChildRow($child, $tr, $link);
      } else {
        // load from server and insert
        that.fetchAndInsertChildRow($link, $tr);
      }
    });
  };

  T.prototype.bindCollapseBar = function() {
    var that = this;
    this.$table.on(R.touchEvent, '.collapse-bar', function (e) {
      var $childRow = $(e.target).closest('tr');
      var $parentRow = $childRow.data(that.parentRowKey);
      var $child = $parentRow.data(that.childContainerKey);
      var $link = $parentRow.find(that.DRToggleLinkSelector);
      that.toggleChildRow($child, $parentRow, $link);
    });
  };

  T.prototype.fetchAndInsertChildRow = function($link, $tr) {
    var that = this;
    var endpoint = $link.data('endpoint');
    if (!endpoint) return;

    // disable link during animation for simpler state maintenance
    $link.addClass('disabled');
    var loaderSrc = '/assets/icons/ajax-loader-company.gif';
    var $loader = $("<img alt='loader' class='loader' src='" + loaderSrc + "'>");
    $loader.insertAfter($link);

    $.get(endpoint)
      .success(function (data) {
        var onAnimationStart = function($childContainer, $childRow){
          $tr.addClass(that.parentRowExpandedClass);
          $childRow.addClass(that.childRowDisplayedClass);
          // Note: storing & toggling child container instead of child row
          // because <tr> element does not animate with slideUp / slideDown
          $tr.data(that.childContainerKey, $childContainer);
          $childRow.data(that.parentRowKey, $tr);
          $loader.remove();
          toggleLinkText($link);
        };

        var onAnimationComplete = function() {
          enableLink($link);
        };

        createChildRow(data, $tr, onAnimationStart, onAnimationComplete);
      }).error(function () {
        $loader.remove();
        $link.addClass('warning'); // leave in disabled state
      });
  };

  function createChildRow(data, $tr, onStart, onComplete) {
    var colspan = $tr.children('td').length;
    var tdStr = '<td colspan="' + colspan + '"></td>';
    var $childRow = $('<tr class="child-row">' + tdStr + '</tr>');
    var $child = $(data);
    $childRow.find('td').html($child);
    $child.hide();
    $childRow.insertAfter($tr);
    onStart($child, $childRow);
    $child.slideDown(onComplete);
  }

  T.prototype.toggleChildRow = function($child, $tr, $link) {
    var that = this;
    $link.addClass('disabled');
    var $childRow = $child.closest('tr');
    if ($child.is(':visible')) {
      $child.slideUp(function () {
        $tr.removeClass(that.parentRowExpandedClass);
        $childRow.removeClass(that.childRowDisplayedClass);
        toggleLinkText($link);
        enableLink($link);
      });
    } else {
      // Unlike for slideUp(), these classes are added before animation
      // so that the parent row is highlighted immediately
      $tr.addClass(that.parentRowExpandedClass);
      $childRow.addClass(that.childRowDisplayedClass);
      toggleLinkText($link);
      $child.slideDown(function () {
        enableLink($link);
      });
    }
  };

  function toggleLinkText($link) {
    var toggleTextKey = 'toggle-text';
    var newToggleText = $link.text();
    var newText = $link.data(toggleTextKey);
    $link.text(newText);
    $link.data(toggleTextKey, newToggleText);
  }

  function enableLink($link) {
    $link.removeClass('disabled');
  }

  T.prototype.removeEvents = function() {
    $('.search-pane input').val('');
  };
  
  
  return T;
})(jQuery, window, document.body, window.R);