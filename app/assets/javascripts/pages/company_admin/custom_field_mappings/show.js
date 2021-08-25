window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_custom_field_mappings-show"] = (function() {

  var CustomFieldMappings = function() {
    this.addEvents();
  };

  CustomFieldMappings.prototype.addEvents = function() {
    new R.CompanyAdmin();
    this.bindBulkEditPageEvents();
  };

  CustomFieldMappings.prototype.bindBulkEditPageEvents = function() {
    this.bindCustomFieldMappingsSuccess();
    this.bindCustomFieldMappingsFormChangeHandler();
  };

  CustomFieldMappings.prototype.removeEvents = function() {
    $document.off('ajaxify:success', '.edit_bulk_custom_field_mapping_updater');
    $('#response-feedback-wrapper').empty();
  };

  CustomFieldMappings.prototype.bindCustomFieldMappingsSuccess = function() {
    $document.on('ajaxify:success', '.edit_bulk_custom_field_mapping_updater', function(e, successObj) {
      var numCustomFieldMappingsCreated = successObj.data.bulk_custom_field_mapping_updater.created_cfms.length;
      var numCustomFieldMappingsUpdated = successObj.data.bulk_custom_field_mapping_updater.updated_cfms.length;

      if (numCustomFieldMappingsCreated > 0) {
        // need to update the rows for created records and make them "updates"
        $.each(successObj.data.bulk_custom_field_mapping_updater.created_cfms, function() {
          var $row = $("#cfm-row-" + this.temporary_id),
              temporaryId = this.temporary_id,
              actualId = this.id;

          $row.find("td").each(function() {
            var $cellEl = $(this);
            $cellEl.find("input").each(function() {
              $(this).attr("value", $(this).val());
            });
            $cellEl.find("select").each(function() {
              $(this).find("option[value='" + $(this).val() + "']").attr("selected", true);
            });
            var cellHTMLStr = $cellEl.html().replace(new RegExp(temporaryId, 'g'), actualId);
            cellHTMLStr = cellHTMLStr.replace(new RegExp('create', 'g'), 'update');
            $cellEl.html(cellHTMLStr);
          });
          $row.attr("id", "cfm-row-" + actualId);
          $row.find(".update_or_create input[type='checkbox']").attr("checked", false).change();
        });
      }

      if (numCustomFieldMappingsUpdated > 0) {
        $.each(successObj.data.bulk_custom_field_mapping_updater.updated_cfms, function() {
          var $row = $("#cfm-row-" + this.id);
          $row.find(".update_or_create input[type='checkbox']").attr("checked", false).change();
        });
      }

      var msg = successFeedbackMessage(numCustomFieldMappingsCreated, numCustomFieldMappingsUpdated);
      successFeedback(msg, $("#edit-custom_field_mappings #response-feedback-wrapper"));
    });
  };

  CustomFieldMappings.prototype.bindCustomFieldMappingsFormChangeHandler = function() {
    $document.on("change", ".update_or_create input[type=checkbox]", function() {
      $(this).parents("tr").removeClass("selected");
    });

    $("#edit-custom_field_mappings").on("change keyup", "input:not([type=checkbox]), select", function() {
      var $row = $(this).parents("tr");
      $row.addClass("selected");
      $row.find("input[type=checkbox]").attr('checked', true);
    });

    $document.on("change", ".provider_type select", function(){
      var $providerKeyIsForMsSchemaExtension = $(this).val() === "ms_graph_schema_extension";
      var $providerAttributeKeyInput = $(this).closest("tr").find(".provider_attribute_key input[type='text']");
      if($providerKeyIsForMsSchemaExtension) {
        $providerAttributeKeyInput.attr("readonly", false);
      } else{
        $providerAttributeKeyInput.val("").attr("readonly", true);
      }
    });
  };

  function successFeedbackMessage(numCustomFieldMappingsCreated, numCustomFieldMappingsUpdated)  {
    var msg;
    if (numCustomFieldMappingsCreated === 0 && numCustomFieldMappingsUpdated === 0) {
      msg = "No extensions were modified";
    } else if (numCustomFieldMappingsCreated > 0 && numCustomFieldMappingsUpdated > 0) {
      msg = numCustomFieldMappingsCreated + " extensions created, and " + numCustomFieldMappingsUpdated + " extensions updated";
    } else if (numCustomFieldMappingsCreated > 0) {
      msg = numCustomFieldMappingsCreated + " extensions created";
    } else {
      msg = numCustomFieldMappingsUpdated + " extensions updated";
    }
    return msg;
  }

  function successFeedback(message, element) {
    var $existingButtons = element.find(".success-mention");
    $existingButtons.remove();
    var $successButton = $('<p class="success-mention success-text">' + message + '</p>');
    element.append($successButton);
    $successButton.fadeOut(4000);
  }

  return CustomFieldMappings;

})();
