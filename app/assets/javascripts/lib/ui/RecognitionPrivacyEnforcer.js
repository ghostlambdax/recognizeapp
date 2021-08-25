/**
 * Privacy enforcer for the Recognition #new page (with revert-ability)
 *
 * @param {Object} $privacyInput: jQuery object containing the main privacy input checkbox
 * @returns {Object} with activate, deactivate & isActive methods.
 */

function RecognitionPrivacyEnforcer($privacyInput) {
  var $socialSharingInputs = $('input[name="recognition[post_to_yammer_wall]"], ' +
                               'input[name="recognition[post_to_fb_workplace]"]');
  var $relevantInputs = $privacyInput.add($socialSharingInputs); // does not mutate

  var stateAttribute = 'initially-checked';
  // this is false by default, but can be true on TL page restore if it was cached in that state
  var isActive = $privacyInput.prop('disabled');

  function updateInputProps($input, props) {
    $.each(props, function (prop, val) {
      $input.prop(prop, val);
    });
  }

  function saveCheckedState($inputs) {
    $inputs.each(function () {
      $(this).data(stateAttribute, this.checked);
    });
  }

  function restoreCheckedState($inputs) {
    $inputs.prop('checked', function () {
      return $(this).data(stateAttribute);
    });
  }

  function updateSocialSharingCheckboxes(opts) {
    if (!$socialSharingInputs.length) { return }

    if (opts.forcePrivacy) {
      updateInputProps($socialSharingInputs, {disabled: true, checked: false});
      $socialSharingInputs.parent().addClass('disabled');
    } else {
      updateInputProps($socialSharingInputs, {disabled: false});
      $socialSharingInputs.parent().removeClass('disabled');
    }
  }

  return {
    activate: function() {
      saveCheckedState($relevantInputs);
      updateInputProps($privacyInput, {checked: true, disabled: true});
      updateSocialSharingCheckboxes({forcePrivacy: true});
      $privacyInput.parent().addClass('disabled'); // for corresponding <label>
      isActive = true;
    },

    deactivate: function() {
      restoreCheckedState($relevantInputs);
      updateInputProps($privacyInput, {disabled: false});
      updateSocialSharingCheckboxes({forcePrivacy: false});
      $privacyInput.parent().removeClass('disabled');
      isActive = false;
    },

    isActive: function () {
      return isActive;
    }
  };
}
