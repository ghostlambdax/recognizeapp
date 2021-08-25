// https://docs.microsoft.com/en-us/microsoftteams/platform/tabs/how-to/create-tab-pages/configuration-page
(function() {
  'use strict';

  R.msTeams = R.msTeams || {};
  R.msTeams.tabConfig = function(companyId, configPersistenceUrl, doRemoveTab) {
    window.R.msTeams.companyId = companyId;
    window.R.msTeams.configPersistenceUrl = configPersistenceUrl;
    window.R.msTeams.removeTabFlow = doRemoveTab;
    document.addEventListener('DOMContentLoaded', function() {
      window.R.msTeams.Loader(init);        
    });
  };

  function init() {
    // Save configuration changes
    getExternalData(initFormState);
  
    if(window.R.msTeams.removeTabFlow) {
      window.R.msTeams.client.settings.registerOnRemoveHandler(onRemoveHandler);
      setupTabRemovalForm();
    } else {
      window.R.msTeams.client.settings.registerOnSaveHandler(onSaveHandler);    
      setupTabConfigForm();    
    }

    // bind tab choice select2
    new window.R.Select2(function() {
      $("#tabChoice").select2();
    });
  }

  // Create the URL that Microsoft Teams will load in the tab. You can compose any URL even with query strings.
  function createTabUrl(eid, includeViewer) {
    var base = window.location.protocol + '//' + window.location.host + '/ms_teams/tab_placeholder';
    if(includeViewer) {
      var queryParamString = "?viewer=ms_teams&entity_id=" + eid;
    } else {
      var queryParamString = "?entity_id=" + eid;
    }
    return base + queryParamString;
  }

  function createTabEntityId() {
    var eid = "tab-"+R.msTeams.companyId+"-"+window.R.utils.guid();
    return eid;
  }

  function currentTabSettings() {
    var eid = getEntityId();
    return {
      websiteUrl: createTabUrl(eid, false), // I think this is the url when you pop up from Ms Teams, so make sure no viewer param
      contentUrl: createTabUrl(eid, true), 
      removeUrl: removeTabUrl(eid),
      entityId: eid, // Mandatory parameter
      suggestedDisplayName: getTabName()
    };
  }

  function deserializeTabEntity(string) {
    return JSON.parse(string);
  }

  function getEntityId() {
    var eid = window.R.msTeams.context.entityId;
    return eid ? eid : createTabEntityId();
  }

  function getExternalData(callback) {
    // first get Microsoft settings
    window.R.msTeams.client.settings.getSettings(function(settings){
      console.log("Got Context", window.R.msTeams.context);
      console.log("Got settings", settings);
      
      if(settings.entityId) {
        // then Recognize settings if we have an entityId 
        // meaning we've saved tab at least once
        var newUrl = window.R.utils.addParamsToUrlString(window.R.msTeams.configPersistenceUrl, {entity_id: settings.entityId});
        $.ajax({
          url: newUrl,
          success: function(data) {
            window.R.msTeams.recognizeSettings = data;
            callback();
          }
        });

      } else {
        callback();
      }
    });
  }

  function getTabName() {
    return $("#tabName").val();
  }

  // requires external data to have been loaded
  // ie this call should be in the callback to getExternalData
  function initFormState() {
    $("#channelName").text(window.R.msTeams.context.channelName);
  }

  function onRemoveHandler(removeEvent) {
    var currentSettings = currentTabSettings();
    var payload = {entity_id: currentSettings.entityId};
    console.log("Attempting removal of tab");

    $.ajax({
      url: window.R.msTeams.configPersistenceUrl,
      type: "delete",
      data: payload,
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));},
      success: function() {
        removeEvent.notifySuccess();
      },
      error: function(xhr, status, err) {
        removeEvent.notifyFailure(err);
      }
    });

  }

  function onSaveHandler(saveEvent) {
    // Let the Microsoft Teams platform know what you want to load based on
    // what the user configured on this page
    var currentSettings = currentTabSettings();
    currentSettings.context = window.R.msTeams.context;
    currentSettings.selectedTab = selectedTab();
    console.log("Saving settings: ",currentSettings);

    var payload = {entity_id: currentSettings.entityId, settings: currentSettings};

    // So, in order to fix other things we added entity_id to the default parameters
    // This has the result of entity being nil when you first add a tab. As a result, 
    // configPersistenceUrl has entity=&viewer=ms_teams. So, when we post this AJAX
    // request, even though we have the entity_id in POST payload, its being ignored and
    // the GET query parameter (the nil entity_id) is taking precedence. 
    // So, we have to work around this by forcing the correct entity_id to be present
    // in the GET query parameter. 
    // This is only an issue when first adding a tab because the proper entity_id will
    // be in the generated configPersistenceUrl from Rails which is what we want anyway. 
    var cpUrl = window.R.utils.addParamsToUrlString(window.R.msTeams.configPersistenceUrl, {entity_id: payload.entity_id});

    // save config to Recognize
    $.ajax({
      url: cpUrl,
      type: "POST",
      data: payload,
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));},
      success: function() {
        window.R.msTeams.client.settings.setSettings(currentSettings);
        // Tells Microsoft Teams platform that we are done saving our settings. Microsoft Teams waits
        // for the app to call this API before it dismisses the dialog. If the wait times out, you will
        // see an error indicating that the configuration settings could not be saved.
        saveEvent.notifySuccess();
      },
      error: function(xhr, status, err) {
        saveEvent.notifyFailure(err);
      }
    });

  }  

  function removeTabUrl(eid) {
    return window.location.protocol + '//' + window.location.host + '/ms_teams/tab_config' + "?viewer=ms_teams&removeTab=true&entity_id=" + eid;
  }

  function selectedTab() {
    return $('#tabChoice').val();
  }

  function setupTabConfigForm() {
    var tabChoice = document.getElementById('tabChoice');

    if (tabChoice) {
      tabChoice.onchange = function() {

        var tab = selectedTab();

        // This API tells Microsoft Teams to enable the 'Save' button. Since Microsoft Teams always assumes
        // an initial invalid state, without this call the 'Save' button will never be enabled.
        // var isValid = window.R.msTeams.tabChoices.indexOf(tab) !== -1;
        var isValid = window.R.msTeams.tabChoices.map(function(item){ return item[1]}).indexOf(tab) !== -1;
        microsoftTeams.settings.setValidityState(isValid);
      };
    }      
  }  

  function setupTabRemovalForm() {
    var $deleteTab = $("#deleteTab");
    window.R.msTeams.client.settings.setValidityState(false);

    if($deleteTab) {
      $deleteTab.on('click', function() {
        var checked = $(this).prop("checked") === true;
        window.R.msTeams.client.settings.setValidityState(checked);
      });
    }
  }
})();
