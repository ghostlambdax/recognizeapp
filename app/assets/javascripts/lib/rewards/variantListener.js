window.R = window.R || {};
window.R.rewards = window.R.rewards || {};
window.$document = window.$document || $(document);

window.R.rewards.variantListener = function() {
  var removeVariantEvent = 'form.new_reward .remove_variant, form.edit_reward .remove_variant',
    addVariantEvent = 'form.new_reward .add_variant, form.edit_reward .add_variant';
  var variantQuantitySelector = '.variants .quantity:visible';
  var variantCheckboxSelector = '.variants .toggle_variant';

  $document.on('click', removeVariantEvent, function(event){
    var $fieldset = $(this).parents('fieldset');
    if(!$fieldset.data("persisted")) {
      $fieldset.remove();
    }
    else{
      $fieldset.find('input.variant_is_enabled').val('0');
      $fieldset.hide();
    }
    updateRewardVariantsQuantityInputsStates();
    event.preventDefault();
  });

  $document.on('click', addVariantEvent, function(event){
    var time = new Date().getTime();
    var regexp = new RegExp($(this).data('id'), 'g');
    $(this).before($(this).data('fields').replace(regexp, time));
    event.preventDefault();
  });

  $document.on("keyup mouseup", variantQuantitySelector, function(){
    updateRewardVariantsQuantityInputsStates();
  });

  // updates relevant hidden `_destroy` input's value when a variant is selected / unselected
  $document.on("change", variantCheckboxSelector, function(e){
    updateDestroyInputStateForDiscreteVariant(e.target);
  });

  $(variantCheckboxSelector).trigger('change')

  return {
    off: function() {
      $document.off('click', removeVariantEvent);
      $document.off('click', addVariantEvent);
      $document.off("keyup mouseup", variantQuantitySelector);
      $document.off("change", variantCheckboxSelector);
    }
  };

  function updateRewardVariantsQuantityInputsStates() {
    var $variantQuantities = $(variantQuantitySelector);
    var variantQuantitiesSum = null;

    $variantQuantities.each(function(){
      var variantQuantityInputFieldValue = $(this).val();
      var variantQuantityInputFieldValueIsNumber = !isNaN(parseInt(variantQuantityInputFieldValue));
      if (variantQuantityInputFieldValueIsNumber) {
        variantQuantitiesSum = variantQuantitiesSum || 0;
        variantQuantitiesSum += parseInt(variantQuantityInputFieldValue);
      }
    });

    if (typeof variantQuantitiesSum === "number") {
      $("#reward_quantity").val(variantQuantitiesSum).prop('disabled', true);
    } else {
      var default_quantity = $("#reward_quantity").data('persisted-quantity') || "";
      $("#reward_quantity").val(default_quantity).prop('disabled', false);
    }
  }

  function updateDestroyInputStateForDiscreteVariant(checkboxElem) {
    $checkbox = $(checkboxElem);
    var enableVariant = $checkbox.prop('checked') ? '1' : '0';
    $checkbox.siblings('.variant_is_enabled').val(enableVariant);
  }

};
