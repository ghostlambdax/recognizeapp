window.R = window.R || {};
window.R.ui = window.R.ui || {};

R.ui.initWYSIWYG = function($targetEl, inputFormatOpts) {
  var INIT_EVENT = 'tbwinit',
      MODAL_OPEN_EVENT = 'tbwmodalopen',
      MODAL_CLOSE_EVENT = 'tbwmodalclose';
  var btnSelector = '.trumbowyg-button-pane button';

  // Need gon for editor settings and image upload path
  if (typeof gon === "undefined"){
    console.error('Recognize: gon not available, skipping initWYSIWYG');
    return;
  }

  var imageUploadPath = gon.recognition_image_upload_path;
  var editorSettings = gon.recognition_editor_settings || {};
  var apiKeyForGiphy = gon.giphy_api_key;

  var buttonList = getButtons(editorSettings, apiKeyForGiphy);
  var pluginOptsList = getPluginOpts(editorSettings, imageUploadPath, apiKeyForGiphy);

  // update input format (hidden field) to html on editor init event
  var wysiwygFormat = 'html';
  if (inputFormatOpts && inputFormatOpts.currentFormat !== wysiwygFormat) {
    $targetEl.one(INIT_EVENT, function () {
      inputFormatOpts.$elem.val(wysiwygFormat);
    });
  }

  $targetEl.trumbowyg({
    svgPath: '/assets/3p/trumbowyg/icons.svg',
    btns: buttonList,
    autogrow: true,
    minimalLinks: true,
    defaultLinkTarget: '_blank',
    removeformatPasted: true,
    plugins: pluginOptsList
  })
  // change tooltip placements from bottom to top so they are shown outside the editor
  .on(INIT_EVENT, function () {
    var $buttons = $('.trumbowyg-button-pane button');
    $buttons.each(function (_i, btn) {
      var $btn = $(btn);
      if ($btn.data('tooltip')) {
        // the tooltip has already been initialized, so just mutate the options hash (usual case)
        $btn.data('tooltip').options['placement'] = 'top';
      } else {
        // the tooltip hasn't been initialized yet, so just set the placement attribute (the case in outlook at least)
        $btn.data('placement', 'top');
      }
    });
  })
  /**
   * Minor UI fix: Disable toolbar tooltips when a modal is open, and restore it back when the modal is closed
   */
  .on(MODAL_OPEN_EVENT, function () { $(btnSelector).tooltip('disable') })
  .on(MODAL_CLOSE_EVENT, function () { $(btnSelector).tooltip('enable') });

  /*
   * Form-loading fix
   * The trumbowyg uploader does not send ajax request when the input is empty (due to internal validation)
   * so we need to manually revert the loading status for submit buttons when the form is submitted that way
   *
   * Note: this listener assumes initWYSIWYG is called once at-most within the same page (or else it would be duplicated)
   * This is de-registered in destroyWYSIWYG method below
   **/
  $document.on(R.touchEvent, '.trumbowyg-modal .trumbowyg-modal-submit', function (e) {
    var $form = $(this).closest('form');
    var $input = $form.find('input[name="url"], input[name="file"]');
    if ($input.length && !$input.val().trim()) {
      resetFormLoadingButton();
    }

    // basic validation for URLs
    var modalTitle = $('.trumbowyg-modal-title').text();
    if (['Insert Image', 'Insert link'].indexOf(modalTitle !== -1)) {
      if (!validateUrlInputInModal($form.closest('.trumbowyg-modal')))
        e.preventDefault();
    }
  });

  function getPluginOpts(settings, uploadPath, giphyApiKey) {
    var pluginOpts = {};

    if (settings['allow_uploading_images']) {
      pluginOpts['upload'] = {
        serverPath: uploadPath,
        fileFieldName: 'file', // param key for uploaded file
        error: errorCallback
      };
    }

    pluginOpts['giphy'] = {
      apiKey: giphyApiKey,
      rating: 'pg'
    };
    return pluginOpts;
  }

  // returns true if valid, otherwise adds validation message and returns false
  function validateUrlInputInModal($modal) {
    var url = $modal.find('input[name="url"]').val();

    /*
     * Perform basic url validation, only allowing http links, so that:
     *  - Data urls and local file paths are rejected, among others.
     *  - The links actually work in the browser. Without the protocol, the browser prefixes the current path to the link
     * regex extended from https://stackoverflow.com/a/15734347
     **/
    var urlRegex = /^https?:\/\/[^ "]+\.[^ "]+$/;
    if (!url.trim() || urlRegex.test(url))
      return true;

    clearPreviousErrorMessages($modal);
    var urlErrors = getUrlErrorMessages();
    // show specific error message when applicable
    var errorMessage = (url.lastIndexOf('http', 0) === -1) ? urlErrors.must_start_with_http : urlErrors.is_invalid;
    displayCustomErrorInModal(errorMessage, $modal);
    resetFormLoadingButton();

    return false;
  }

  function getButtons(settings, giphyApiKey) {
    var buttons = ['strong', 'em'];
    // link button
    if (settings['allow_links']) {
      buttons.push('link');
    }

    // image buttons
    if (settings['allow_inserting_images']) {
      buttons.push('insertImage');
    }
    if (settings['allow_uploading_images']) {
      buttons.push('upload');
    }

    // giphy button
    if (settings['allow_gif_selection'] && giphyApiKey) {
      buttons.push('giphy');
    }

    return buttons;
  }

  function errorCallback(xhr, _textStatus, _errorThrown) {
    var $modal = $('.trumbowyg-modal');

    clearPreviousErrorMessages($modal);
    if (xhr.responseJSON && xhr.responseJSON.message){
      var errorMessage = xhr.responseJSON.message.trim();
      errorMessage = errorMessage.replace(/^\^/, ''); // remove caret prefix. This is usually handled by JsonResource
      displayCustomErrorInModal(errorMessage, $modal);
    } else {
      // this is the default behavior (apart from the status mapping),
      // which is no longer present when error callback is specified
      var errorMap = { 401: 'Not authorized', 422: 'Invalid file' };
      var errorTitle = errorMap[xhr.status] || 'Error';
      var $defaultError = $('<span>', {class: 'trumbowyg-msg-error', text: errorTitle});
      var $fileInputContainer = $modal.find('input[type="file"] + .trumbowyg-input-infos');
      $defaultError.appendTo($fileInputContainer);
      $fileInputContainer.parent('label').addClass('trumbowyg-input-error');
    }

    // this is only needed for erroneous cases, as the modal closes upon success.
    resetFormLoadingButton();
  }

  function clearPreviousErrorMessages($modal) {
    var $customError = $modal.find('.trumbowyg-custom-error');
    if ($customError.length) {
      $customError.remove();
      var originalHeight = $modal.data('original-height');
      if (originalHeight) { $modal.height(originalHeight); }
    }

    var $defaultError = $modal.find('.trumbowyg-msg-error');
    if ($defaultError.length) {
      $defaultError.closest('label').removeClass('trumbowyg-input-error');
      $defaultError.remove();
    }
    return $customError;
  }

  function displayCustomErrorInModal(errorMessage, $modal) {
    var $customError = $('<div>', {class: 'trumbowyg-custom-error', text: errorMessage});
    $customError.prependTo($modal.find('form'));

    var expandedMargin = 20; // margin between title and file input, which overlaps when this custom error is absent
    $modal.data('original-height', $modal.height());
    $modal.height($modal.height() + $customError.outerHeight() + expandedMargin); // reset static modal height
  }

  function resetFormLoadingButton() {
    // FormLoading is currently unavailable in /new_panel path (i.e. Outlook)
    if (window.recognize && window.recognize.patterns && window.recognize.patterns.formLoading) {
      window.recognize.patterns.formLoading.resetButton();
    }
  }

  function getUrlErrorMessages() {
    var defaults = {
      must_start_with_http: 'URL should start with http',
      is_invalid: 'URL is not valid'
    };
    return $.extend(defaults, gon.url_error_messages);
  }
};

R.ui.destroyWYSIWYG = function($targetEl) {
  // Buttons for previously open modals do not work on turbolinks restore
  // as their callbacks are only registered when opening the modal
  $targetEl.trumbowyg('closeModal');

  // This line is extracted from above method's implementation - there is a 100ms delay when this is executed there
  // due to animation, which causes it to be executed on a different page
  $('.trumbowyg-modal').remove();

  // Finally destroy the editor so it can be re-initialized on turbolinks restore
  $targetEl.trumbowyg('destroy');

  // remove event listener registered in initWYSIWYG
  $document.off(R.touchEvent, '.trumbowyg-modal .trumbowyg-modal-submit');
};