window.R = window.R || {};

window.R.Cards = (function($, window, body, R, undefined) {
  var canCloseMenu = true;
  var cardSelector = ".recognition-card";

  var Cards = function(container, callback, options) {
    rLog('Start of cards');

    this.container = container || "#stream";
    this.$container = $(this.container);
    this.callback = callback || function () {
    };
    this.options = options || {};
    this.infiniteScrollPath = this.options.infiniteScrollPath || ".recognition-card .pagination .next_page";
    this.mobileInfiniteScroll = isMobile();

    this.addEvents();
    this.loadComments();
    this.loadApprovals();
  };

  Cards.prototype.openMenu = function(e) {
    if (canCloseMenu) {
      canCloseMenu = false;
      $(this).closest(cardSelector).toggleClass("options-open");
      setTimeout(function() {
        $document.trigger("recognition:change");
      }, 100);

      setTimeout(function() {
        canCloseMenu = true;
      }, 500);
    }
  };

  function startIsotope() {
    var layoutMode = this.options.layoutMode || "vertical";
    var $container = $(this.container);

    $container.isotope({
      itemSelector : cardSelector + ':not(.hidden)',
      layoutMode: layoutMode
    });
  }

  function isStream() {
    var bodyId = $body.attr('id');
    return (["recognitions-index", "recognitions-grid"].indexOf(bodyId) !== -1);
  }

  function isMobile() {
    return window.outerWidth < 768;
  }

  // values here should be in sync with controller
  function getPerPageCount() {
    var perPage;

    if (isStream() && R.utils.isFullscreen()) {
      perPage = 15;
    } else {
      perPage = 10;
    }

    return perPage;
  }

  Cards.prototype.initIsotope = function() {
    startIsotope.call(this);
  };

  /*
  *  watches images in recognition message and triggers recognition:change when each image is loaded
  *  unlike simple image load listener, this works for:
  *    - cached images as well
  *    - already-loaded images as well (where callback is fired immediately)
  *
  *  Note: the plugin only checks current images in DOM, so this needs to be invoked whenever new content is added
  * */
  Cards.prototype.bindImagesLoaded = function($cardEls) {
    var that = this;
    var $container = this.$container;
    $cardEls = $cardEls ? $($cardEls) : $container.find('.r-r-card');

    $cardEls.imagesLoaded().progress( function(_imagesLoaded, loadingImage) {
      var $img = $(loadingImage.img);

      // ignore irrelevant images like badge, user images, etc.
      if (!$img.closest('.message', $container).length)
        return;

      var $cardEl = $img.closest('.recognition-card');
      $document.trigger("recognition:change", { checkOverlay: true, cardElements: $cardEl});
    });
  };

  Cards.prototype.startScroll = function() {
    var that = this;
    var perPageCount = getPerPageCount();
    var $scrollElement = this.$container;

    // Not if it is full screen OR if it is only Stream page not on mobile tho and it has Teams showing on Stream.
    var shouldScrollElement = !R.utils.isFullscreen() && (isStream() && !isMobile() && ($(".no-teams").length === 0));

    $scrollElement.infiniteScroll({
      elementScroll: shouldScrollElement,
      path: function (){
        return $(this.infiniteScrollPath).attr('href');
      }.bind(this),
      append: cardSelector,
      prefill: false,
      responseType: 'document',
      outlayer: {
        appended: function( newElements ) {
          R.utils.safe_feather_replace(); // for read-more icon

          if (newElements.length) {
            that.bindImagesLoaded(newElements);

            // isotope is currently enabled for kiosk page only
            if (R.utils.isFullscreen())
              updateIsotopeAfterPagination(newElements);
          }

          NProgress.done();

          /*
           * Fix to manually stop infinite scroll when no further cards present
           * Needed because checkLastPage option is set to false here, as it is problematic on User#show page
           *   because it uses custom `path` selector to target active scroll container from multiple others in the page
           **/
          if (newElements.length < perPageCount)
            that.$container.infiniteScroll('destroy');

          $document.trigger("recognition:change", { checkOverlay: true, cardElements: newElements});

          that.loadComments(newElements);
          that.loadApprovals(newElements);
        }
      },
      scrollThreshold: 400,
      loadOnScroll: true,
      history: true, // 'replace',
      historyTitle: true,
      hideNav: false,
      status: false,
      button: false,
      checkLastPage: false
    });

    this.$container.on( 'request.infiniteScroll', function( event, path ) {
      NProgress.start();
    });

    // why the next pagination url in the DOM needs to be updated:
    // - this is the authoritative link for the next pagination (looked up manually from the :path function)
    // - it preserves the pagination state during turbolinks page restore
    this.$container.on( 'load.infiniteScroll', function( event, response, _currentPath ) {
      var hasMultipleInfiniteScrollContainers = $(response).find('.pagination .next_page').length > 1;
      var relevantContainerWithPagination = hasMultipleInfiniteScrollContainers ?
          $(response).find("#" + $(event.target).attr('id')) :
          $(response);

      // note: undefined does not work for unsetting attribute so use null (at end of pagination)
      var nextPath = relevantContainerWithPagination.find('.pagination .next_page').attr('href') || null;

      $(this.infiniteScrollPath).attr('href', nextPath);
    }.bind(this));

    // TODO: confirm modification made to this method in the UI
    function updateIsotopeAfterPagination(newElements) {
      var $newElements = $(newElements);
      that.$container.isotope('appended', $newElements);
      if (!Modernizr.backgroundsize) {
        $(cardSelector + " .image-wrapper").css("background-size", "150px");
      }
    }
  };

  Cards.prototype.addEvents = function() {
    // Note: although this is automatically done on page load,
    //       which seems to suffice for most views that render cards,
    //       it is still needed, atleast, for views where cards are rendered manually, specifically stream teams.
    R.utils.safe_feather_replace(); // for read-more icon
    this.checkRedundantOverflowOverlays();

    var that = this;
    var resizeTimer = 0;

    rLog('Start of Add Events in Cards');

    $document.on("recognition:change", function (_e, opts) {
      // for card expansion, this timeout should be in sync with the animation duration in CSS
      var timeout = 500;

      if (opts && opts['checkOverlay']) {
        opts['timeout'] = timeout; // not used by default
        invokeCheckOverlayOnRecognitionChange(that, opts)
      }

      if ($(that.container).data('isotope')) {
        setTimeout(function () {
          $(that.container).isotope("reLayout");
        }, timeout);
      }
    });

    rLog('Before full Screen', R.utils);
    if (R.utils.isFullscreen()) {
        this.options.layoutMode = 'masonry';
        this.initIsotope();
    }

    this.bindImagesLoaded();

    rLog('turning off opacity0', this.$container);
    this.$container.removeClass("opacity0");


    // pagination element is absent when insufficient cards
    // the link href is also null in an edge case when returning to page after pagination is complete
    if ($(this.infiniteScrollPath).attr('href') && this.$container.find(cardSelector).length > 0) {
      this.startScroll();
    }

    if (this.callback) {
      this.callback();
    }

    $body.on("click", '.cancel-edit', function(e){
      var $form = $(e.target).parents('form.edit_recognition');
      $form.closest(".edit-open").removeClass("edit-open");
      $form.remove();
      $document.trigger("recognition:change");
      e.preventDefault();
    });

    $document.on({
      mouseenter: that.showApprovalList,
      mouseleave: function(e) {
        $(this).find(".approval-list").css({"display": "none"});
      },
      click: that.showApprovalList
    }, ".moreValidationNames");

    this.$container.on(R.touchEvent, ".options-trigger", this.openMenu);

    $document.one("turbolinks:before-cache", this.unload.bind(this));

    $window.on('resize.cards', function() {
      clearTimeout(resizeTimer);

      resizeTimer = setTimeout(function() {
        $document.trigger("recognition:change", { checkOverlay: true });

        // pagination link can be missing or disabled if pagination is not needed / has been exhausted
        if (!$(that.infiniteScrollPath).attr('href'))
          return;

        if (isStream()) {
          if (window.outerWidth < 768 && !that.mobileInfiniteScroll) {
            that.resetInfiniteScroll();
            that.mobileInfiniteScroll = true;
          } else if (window.outerWidth > 768 && that.mobileInfiniteScroll) {
            that.resetInfiniteScroll();
            that.mobileInfiniteScroll = false;
          }
        }
      }, 200);
    });

    $document.on(R.touchEvent, ".recognition-delete .button", function(){
      var deleteForm = $(this).parent("form");
      var translation = gon.translations_for_recognition_delete_swal;
      Swal.fire({
        title: translation.title ,
        text: translation.label ,
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: translation.confirm_text,
        cancelButtonText: translation.cancel_text,
        closeOnConfirm: false,
        customClass: 'destroy-confirm-button'
      }).then(swalThenCallback.bind(this, deleteForm));

      function swalThenCallback(deleteForm, result) {
        if (result.value) {
          deleteForm.submit();
        }else{
          var inputSubmit = deleteForm.find("input[type='submit']")
          inputSubmit.removeClass("form-loading-button");
          inputSubmit.attr("value", "Delete");
        }
      }
      return false;
    });

    this.$container.on(R.touchEvent, ".read-more", this.readMore.bind(this));
  };

  Cards.prototype.loadComments = function(recognitionCards) {
    var that = this;
    // animated loading effect
    this.$container.find('.loading .comment-text').width('80%');
    this.$container.find('.loading .comment-text.w-60').width('60%');
    if(typeof(recognitionCards) === 'undefined') {
      recognitionCards = this.$container.find(".recognition-card.r-r-card");
    } else {
      recognitionCards = $(recognitionCards);
    }
    var recognitionIds = extractRecognitionIds(recognitionCards);
    if(recognitionIds.length !== 0) {
      $.get(gon.comments_async_endpoint, { recognition_ids: recognitionIds, grid_view: this.options.gridView })
      .done(function(data) {
        NProgress.done(true);
        var recognitionsComments = data.recognitions_comments;
        $.each(recognitionsComments, function(i, recognitionComment) {
          if(that.$container) {
            var recognitionCard = that.$container.find('.recognition-card#recognition-card-' + recognitionComment.recognition_id);
            var commentWrapper = recognitionCard.find('.comment-wrapper');
            if (recognitionComment.comments) {
              commentWrapper.empty().append(recognitionComment.comments);
            } else {
              commentWrapper.remove();
            }
          }
        });
        $document.trigger("recognition:change");
      });
    }
  };

  Cards.prototype.loadApprovals = function(recognitionCards) {
    var that = this;
    if(typeof(recognitionCards) === 'undefined') {
      recognitionCards = this.$container.find(".recognition-card.r-r-card");
    } else {
      recognitionCards = $(recognitionCards);
    }
    var recognitionIds = extractRecognitionIds(recognitionCards);
    if(recognitionIds.length !== 0) {
      $.get(gon.approvals_async_endpoint, { recognition_ids: recognitionIds })
      .done(function(data) {
        var recognitionsApprovals = data.recognitions_approvals;
        $.each(recognitionsApprovals, function(i, recognitionApproval) {
          if(that.$container) {
            var recognitionCard = that.$container.find('.recognition-card#recognition-card-' + recognitionApproval.recognition_id);
            if(recognitionCard.find('#recognition-approval-' + recognitionApproval.recognition_id).length < 1) {
              recognitionCard.find('.recognition-action-wrapper').prepend(recognitionApproval.approvals);
            }
          }
        });
        $document.trigger("recognition:change");
      });
    }
  };

  Cards.prototype.unload = function() {
    $(document)
    .off(R.touchEvent, cardSelector)
    .off(R.touchEvent, '.cancel-edit');

    $document.off("recognition:change");
    $window.off('resize.cards');
    var $container = this.$container;
    if ($container) {
      $container.off(R.touchEvent, ".options-trigger");
      R.utils.destroyInfiniteScroll($container);
    }
    delete this.$container;
  };

  /**
   * Usage Note: this is used for Stream pages only (default / grid)
   *
   * Known issue Note:
   *   when switching to teams in mobile and then resizing to desktop and back to mobile,
   *   the infinitescroll watch for cards is not paused / destroyed,
   *   thus causing pagination requests for recognitions when scrolling teams (in the mobile screen)
   */
  Cards.prototype.resetInfiniteScroll = function() {
    $document.trigger("resize:infiniteReset");
    R.utils.destroyInfiniteScroll(this.$container);
    this.startScroll();
  };

  Cards.prototype.showApprovalList = function(e){
    var approvalList = $(this).find(".approval-list");
    var approversCount = approvalList.find("li").length;
    var textHeight = 15;
    var padding = 10;
    var height = approversCount * textHeight;
    approvalList.css({"display": "block", "height": height+padding+"", "top" : "-"+(height+5)+"px"});
  };

  Cards.prototype.readMore = function (evt) {
    // target could be read more link itself or its children
    var $readMoreLink = $(evt.target).closest('.read-more');

    // only expand if it's the first click - it should behave like a normal link the second time
    if ($readMoreLink.data('expanded'))
      return;

    evt.preventDefault();

    $readMoreLink.closest('.message-outer').addClass('expanded');

    // set data for next click
    // using attr() instead of data() so that it is persisted on the DOM during turbolinks restore
    $readMoreLink.attr('data-expanded', true);

    // needed for grid page that still uses isotope
    // Timeout note: Not using timeout for the trigger itself here because the listener for this event already
    //               has a default timeout, which is the same as the duration of the transition for the card expansion
    var $cardEl = $readMoreLink.closest('.recognition-card');
    $document.trigger("recognition:change", { checkOverlay: true, cardElements: $cardEl, useTimeoutForOverlayCheck: true });
  }

  /*
  * Experimental enhancement (run on init/resize)
  *
  * Hides message overlays for cards where the content height is less than the allowed max height
  *   Although the overlay is already implicitly hidden for the vast majority of such cards,
  *   it is visible in a few cases, where the content height is just slightly shorter than the allowed max-height, where:
  *   - it is partially cutoff in most cases (with the read more link often hidden)
  *   - it does not result in expansion of the card height upon clicking read more, as there is no content below it.
  *
  * Known bugs: (unusual cases)
  *   - The height calculation for .message below can be inaccurate in the following case, due to which the overlay is hidden when it shouldn't be:
  *     when the message has disproportional number of tags, and extra closing tag(s) matching with the parent container's opening tag,
  *     then the wrapping container (.message) will be closed prematurely, with the remaining content overflowing to its parent container
  *     (this can happen during copy/paste - although it probably won't happen with new recognitions as removeformatPasted has just been set to true)
  #
  * @param {jQuery obj / NodeList / selector string} cardEls
  *
  * */
  Cards.prototype.checkRedundantOverflowOverlays = function(cardEls) {
    rLog("callback: checkRedundantOverflowOverlays");

    var $cardEls = cardEls ? $(cardEls) : this.$container.find('.recognition-card.r-r-card');
    var $msgWrapperEls = $cardEls.find('.message-outer');

    $msgWrapperEls.each(function() {
      var $msgWrapper = $(this);

      var $msg = $msgWrapper.find('.message');
      var $overlay = $msgWrapper.find('.overflow-overlay');

      if ($msgWrapper.innerHeight() >= $msg.outerHeight()) { // if no overflow
        // hiding all overlays here for simplicity
        // we could just hide the ones currently visible in the viewport, but that seems complicated
        $overlay.hide();
      } else {
        $overlay.show();
      }
    });
  };

  function extractRecognitionIds(cards) {
    var ids = [];
    $.each(cards, function(i, card) {
      var id = $(card).attr('id');
      if(typeof(id) !== 'undefined') {
        ids.push(id.split('-')[2]);
      }
    });
    return ids;
  }

  function invokeCheckOverlayOnRecognitionChange(instance, opts) {
    var checkOverlay = function () {
      instance.checkRedundantOverflowOverlays(opts['cardElements']);
    }

    // false by default, only needed during card expansion
    if (opts['useTimeoutForOverlayCheck']) {
      setTimeout(checkOverlay, opts['timeout']);
    } else {
      checkOverlay();
    }
  }

  return Cards;

})(jQuery, window, document.body, window.R);
