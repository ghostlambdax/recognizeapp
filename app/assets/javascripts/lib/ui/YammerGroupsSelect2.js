window.R = window.R || {};

R.YammerGroupsSelect2 = function() {
  'use strict';
  return {
    initialize: function() {
      var $yammerGroupsWrapper = $(".yammer-groups-wrapper");
      var endpoint = $yammerGroupsWrapper.data("endpoint");

      function done(data) {
        var options = data.available_groups;
        var selectOptions = [];
        if (options.length > 0) {
          selectOptions =  $.map(options, function (option) { return new Option(option.full_name, option.id) });
        } else {
          selectOptions = [new Option("Unavailable")];
        }

        var select2 = $yammerGroupsWrapper.find("select").select2();
        select2.append(selectOptions);
        if (data.default_group_id) {
          select2.val(data.default_group_id);
        }
        select2.trigger("change");
        $yammerGroupsWrapper.find(".reauthenticate-if-needed-wrapper").show();
        $yammerGroupsWrapper.find(".select-wrapper").show();
      }

      function failed(xhr){
        $yammerGroupsWrapper.find(".warning").empty().append(xhr.responseText);
        $yammerGroupsWrapper.find(".warning-wrapper").show();
        // Show select even though its disabled and empty (so that validation errors can be tagged to proper tag)
        $yammerGroupsWrapper.find(".select-wrapper").show();
      }

      R.utils.select2RemoteSingleton(endpoint, $yammerGroupsWrapper).then(done, failed);
    }
  };
}();