window.Autocomplete.recognizeAutocomplete = (function() {
  'use strict';

  var emailTemplate = Handlebars.compile( $("#emailItem").html() );
  var userTemplate = Handlebars.compile( $("#userItem").html() );
  var teamTemplate = Handlebars.compile( $("#teamItem").html() );

  // Format autocomplete data from Yammer
    // to confirm to the data expected by Recognize's handlebar templates
    // Need:
    //    - avatar_thumb_url
  //    - label
  //    - network label
  function formatYammerUser(user) {
    var parentCompanyName = $body.data("parent-name");
    var person = user;

    person.label = user.full_name;
    person.avatar_thumb_url = user.photo;

    return person;
  }

  function getEmailMetadataEntity(items) {
    var emailMetadataEntity,
      possibleEmailMetadataEntity = items[items.length-1];
    // If possibleEmailMetadataEntity is user or team (both of which have id), search for `search term' in items.
    if (possibleEmailMetadataEntity.id) {
      for(var i=0; i < items.length; i++){
        var item  = items[i];
        if (!item.id){
          // Search term doesn't have an id, unlike user or team.
          emailMetadataEntity = item;
          break;
        }
      }
    }else {
      emailMetadataEntity = possibleEmailMetadataEntity;
    }
    return emailMetadataEntity;
  }

  return {
    _renderMenu: function(ul, items) {
      var $html,
          itemsLength = items.length,
          counter = 0,
          person,
          emailMetadataEntity = getEmailMetadataEntity(items),
          personOrTeam;

      if (itemsLength >= 1) {
        while (counter < itemsLength) {
          var user = items[counter];
          var team;

          if (user.email) {
              if (R.userTeamMap && R.userTeamMap != null) {
                  team = R.userTeamMap[user.email];
              }


              // hack to massage autocomplete data from Yammer
              // to conform to the data expected by Recognize's handlebar templates
              // person.web_url is only present when data comes from yammer
            person = user;
            if (user.web_url) {
              person = formatYammerUser(person);
            }

            if(team && team.length > 0) {
              person.team = team;
            }

            if (person && !person.label) {
              person.first_name = person.email;
              person.last_name = null;
            }

            if (person.job_title && person.job_title.length) {
              person.jobTitle = person.job_title;
            }

            if (person.avatar_thumb_url === R.defaultAvatarPath) {
              person.avatar_thumb_url = "/assets/" + R.defaultAvatarPath;
            }

            personOrTeam = $( userTemplate({items: person}) ).data("ui-autocomplete-item", person);

          } else if(user.id) {
            personOrTeam = $( teamTemplate({items: user}) ).data("ui-autocomplete-item", user);
          }

          if(user.type) {
            personOrTeam.addClass(user.type.toLowerCase());
          }

            if (personOrTeam) {
                ul.append(personOrTeam);
            }

            counter++;
        }
      }

        if (emailMetadataEntity.value.indexOf('@') > -1) {
            ul.append($(emailTemplate(emailMetadataEntity)).data("ui-autocomplete-item", {email: emailMetadataEntity.value}));
        }

        return ul;
    }
  };
});
