window.R = window.R || {};
window.R.ui = window.R.ui || {};

window.R.ui.Post = (function() {
  var $newPost;
  var yammerGroupSelectInitialized = false;



  var Post = function(type, options) {
    var options = options || {};

    this.createUsers = options.createUsers || true;
    this.type = type || "recognition";
    this.transition = R.transition;

    this.badgeList = new window.R.ui.BadgeList(this.type);
    this.$recipient_name = $("#"+this.type+"_recipient_name");
    this.$form = $("#new_"+this.type);
    this.$recipients = $("."+this.type+"_recipients");
    this.$message = $("#"+this.type+"_message");

    this.recognitionTagsPresent = (this.type === 'recognition') && $('#recognition_tag_ids').length;
    this.addEvents();
    this.initAutoComplete();

    if (R.recipients && R.recipients.length) {
        R.recipients.forEach(function(r) {
            this.addRecepient( r );
        }.bind(this));
    }

    if ($html.hasClass("ie8") || $html.hasClass("ie9")) {
      var inputValue = this.$recipient_name.attr('placeholder');
      this.$recipient_name.attr("placeholder", "").attr("value", "");
      this.$recipient_name.before($("<label>"+inputValue+"</label>"));
    }

    // Fix old IE issue where placeholder becomes value on textarea duplication, manifested on turbolinks restore
    // https://github.com/turbolinks/turbolinks-classic/issues/455
    var $textAreaField = $('#recognition_message, #nomination_vote_message');
    if (R.utils.isIE() && ($textAreaField.val() === $textAreaField.attr('placeholder'))) {
      $textAreaField.val('');
    }

    if (this.type === 'recognition') {
      new window.R.BadgesRemaining($("#badge-list"));

      this.setupWysiwygIfRequired(gon.recognition_wysiwyg_editor_enabled, gon.recognition_format, options['page']);
    }
  };

  Post.prototype.addEvents = function() {
    $newPost = this.$form;
    var timer = 0;
    var that = this;
    var $options = $("input[type=checkbox]");

    if ($options.length) {
      $options.change(function() {
          var $this = $(this);
          var name = $this.attr("name");

          switch(name) {
            case "recognition[post_to_fb_workplace]":
              if ($this.is(":checked")) {
                $("[name='recognition[is_private]']").prop("checked", false).change();
              }
              break;

            case "recognition[post_to_yammer_wall]":
              that.handleRecognitionPostToYammerWallToggle($this.is(":checked"));
              break;

            case "recognition[is_private]":
              that.handleRecognitionIsPrivateInputToggle($this.is(":checked"));
              break;
          }
        }
      );
    }

    if($('input[name="recognition[post_to_yammer_wall]"]:checked').length > 0 && $(".yammer-groups-wrapper").length > 0) {
      this.handleRecognitionPostToYammerWallToggle(true);
    }

    this.$partialFormWrapper = $("#"+this.type+"-form-wrapper");
    this.$recepient = $("#chosen-recepient-wrapper");

    $document.on(R.touchEvent, "."+this.type+"-overlay-close", this.closeOverlays);

    $window.keyup(function(e) {
      if ( e.keyCode === 27 && ( $("#recognize-badge-list-wrapper.current").length || $("#recognize-reward-wrapper.current").length ) ) {
        R.transition.fadeTop();
      }
    }.bind(this));

    $window.resize(function() {
      clearTimeout(timer);
      timer = setTimeout(function() {
        hasLoadedIsotope = false;
      }, 500);
    });

    $document.on(R.touchEvent, ".button-yammer-signup", this.setFormAttrsOnYammerBtn);

    $newPost.submit(function(e) {
      e.preventDefault();
      this.beforeSend();
    }.bind(this));

    $newPost.bind("ajax:beforeSend", function(e, xhr, settings){
      var params = R.utils.paramStringToObject(settings.data)
      params[this.type+"[recipients][]"];
    });
    $newPost.bind("ajax:success", this.send.bind(this));

    $window.bind("ajaxify:errors", function() {
      $("#recognition-new-wrapper #top").scrollTop(0);
    }.bind(this));

    $document.on(R.touchEvent, ".recipient-remove", this.removeRecipient.bind(this));
    if (this.recognitionTagsPresent) {
      this.initTagsSelect2();
    }
  };

  Post.prototype.handleRecognitionIsPrivateInputToggle = function(isChecked) {
    var $postToYammerWallInput = $("[name='recognition[post_to_yammer_wall]']");
    var $postToFbWorkplaceInput = $("[name='recognition[post_to_fb_workplace]']");

    if (isChecked === true) {
      $postToFbWorkplaceInput.prop("checked", false).change();

      if ($postToYammerWallInput.attr("type") === "checkbox") {
        $postToYammerWallInput.prop("checked", false).change();
      }
      if ($postToYammerWallInput.attr("type") === "hidden") {
        $postToYammerWallInput.data("original_value", $postToYammerWallInput.val());
        $postToYammerWallInput.val(false);
      }
    } else {
      if ($postToYammerWallInput.attr("type") === "hidden") {
        $postToYammerWallInput.val($postToYammerWallInput.data("original_value"));
        $postToYammerWallInput.removeData("original_value");
      }
    }
  };

  Post.prototype.handleRecognitionPostToYammerWallToggle = function(isChecked) {
    var $isPrivateInput = $("[name='recognition[is_private]']");
    var $yammerGroupWrapper =  $(".yammer-groups-wrapper");

    if (isChecked === true) {
      $isPrivateInput.prop("checked", false).change();
      $yammerGroupWrapper.show();
      if (!yammerGroupSelectInitialized){
        R.YammerGroupsSelect2.initialize();
        yammerGroupSelectInitialized = true;
      }
    } else {
      $yammerGroupWrapper.hide();
    }
  };

  Post.prototype.removeEvents = function() {
    $document.off("change", "#postYammer input.on-off");
    $document.off(R.touchEvent, ".recipient-remove");
    if (this.autocomplete) {delete this.autocomplete;}
    $window.unbind("keyup");
    if ($newPost) {
      $newPost.unbind("ajax:beforeSend");
      $newPost.unbind("ajax:success");
    }

    if (this.recognitionTagsPresent) {
      R.utils.saveSelectValuesToDom('#recognition-form-extras');
    }

    if (this.badgeList) {
      this.badgeList.removeEvents();
    }

    if (this.wysiwygEditorInitialized) {
      R.ui.destroyWYSIWYG($('#recognition_message'));
    }

    yammerGroupSelectInitialized = false;
  };

  Post.prototype.closeOverlays = function() {
    R.transition.fadeTop("#recognition-new-wrapper");
  };

  Post.prototype.setFormAttrsOnYammerBtn = function(evt) {
    var $yammerBtn = $(".button-yammer-signup");
    var recognition = {
      badge_id: $("#"+this.type+"_badge_id").val(),
      recipient_email: this.$recipient_name.val(),
      message: this.$message.val()
    };
    var href = $yammerBtn.attr('href').split("?")[0];
    href = href+"?"+$.param({recognition : recognition}, false);
    $yammerBtn.attr('href', href);
  };

  Post.prototype.beforeSend = function(e) {
    $(".message-info").remove();

    this.removeErrors();
  };

  function recipientAlreadyInRecipientsList(userData) {
    var alreadyInList = false;
    var expectedSignatureDataAttributeValue = null;
    if (userData.email){
      expectedSignatureDataAttributeValue = userData.email;
    } else if (userData.id){
      expectedSignatureDataAttributeValue = userData.type + ":" + userData.id;
    }
    if (expectedSignatureDataAttributeValue) {
      alreadyInList = $("[data-signature]").filter(function(){
        return $(this).data("signature") === expectedSignatureDataAttributeValue;
      }).length > 0;
    }
    return alreadyInList;
  }

  Post.prototype.addRecepient = function(userData) {
    if (recipientAlreadyInRecipientsList(userData)) {
      return;
    }

    var $html;

    if (!userData.type) {
      userData.type = 'email';
    }

    if (userData.type && userData.type.toLowerCase() === "team") {
      userData.count = gon.team_counts[userData.id] || 0;
    }

    var html = Handlebars.compile( $("#addRecepient").html() )(userData); // Compile returns a function and then we pass in the data to that.

    $html = $(html);
    if (userData.type.toLowerCase() === "team") {

      $html.addClass("team");
    }

    $body.focus();

    this.$recepient.removeClass("no-recipients").find(".inner").append($html);

    $("#main-text .hidden-field").val("");

    // the idea here is that we start on page load with
    // one hidden recipient field.  The first recipient is added by user
    // and that data is populated into that first hidden field
    // for, all subsequent recipients we need to add more hidden fields
    // The reason for this is when no recipients are added it gives me a field
    // to add errors on to while keeping the error field consistent with the field
    // that is actually passed on form submit
    var $hidden_recipient_field;
    if(this.$recipients.length === 1 && this.$recipients.val() === "") {
      $hidden_recipient_field  = this.$recipients.first();
    } else {
      var index = this.$recipients.last().data('index')+1;
      $hidden_recipient_field = $("<input>");
      $hidden_recipient_field.prop({
        type : 'hidden',
        id : this.type+'_recipients_'+index,
        'class' : this.type+'_recipients',
        name : this.type+'[recipients][]'});

      $hidden_recipient_field.data('index', index);
    }

    if ( userData.web_url || userData.email ) {
      $hidden_recipient_field.val(userData.email);
    } else {
      $hidden_recipient_field.val(userData.type+":"+userData.id);
    }

    this.$form.append($hidden_recipient_field);

    setTimeout(function() {
      this.$recipient_name.focus();
    }.bind(this), 100);

    $document.trigger("addedRecipient", userData);
  };

  Post.prototype.removeRecipient = function(evt) {
    var $el = $(evt.target);
    var $target = $el.closest('.recipient-wrapper');
    var objSignature = $target.data('signature');

    $target.remove();
    $("."+this.type+"_recipients[value='"+objSignature+"']").remove();

    $document.trigger("removedRecipient", [$target.hasClass("team"), $el]);
  };

  Post.prototype.initAutoComplete = function() {
    if (window.Autocomplete) {
      this.autocomplete = new window.Autocomplete({
        input: "#"+this.type+"_recipient_name",
        success: this.addRecepient.bind(this),
        createUsers: this.createUsers,
        includeSelf: this.includeSelf()
      });
    }
  };

  // Todo make yammer work better
  Post.prototype.send = function(e, data) {
    var $chosenBadge,
      senderName,
      badgeName,
      title,
      badgeImagePath,
      recognitionURL;

    if (data.type === "error") {
      return;
    }

    $chosenBadge = $(".button-dark");
    senderName = $("#sender_name").val();
    badgeName = ( $chosenBadge.text() ).replace(/(\r\n|\n|\r|" ")/gm, "").trim();
    title = $("#recognition_recipient_name").val() + " received the " + badgeName + " badge from "+ senderName + '.';
    recognitionURL = data.permalink;

    badgeImagePath = $chosenBadge.siblings(".badge-image-small").data("imagepath");

    if ($("#yammer-toggle").prop("checked")) {
      R.y.postMessage({
        title: title,
        image: badgeImagePath,
        url: recognitionURL,
        message: this.$message.val()
      });
    }

    if(data.flash) {
      this.cleanup(data.flash.notice);
    }
  };

  Post.prototype.includeSelf = function() {
    if(this.type === 'recognition') {
      return false;
    }

    return true;
  };

  Post.prototype.cleanup = function(message) {
    // reset the button
    $(".button-primary").removeClass("button-primary").find(".icon-ok").addClass("opacity0");
    // clear form fields
    $("input[type=text], textarea").val("");

    // display the message
    $("#recognition-form-wrapper").prepend("<div class=message-info><h4>"+message+"</h4></div>");

    // hide error messages
    this.removeErrors();
  };

  Post.prototype.removeErrors = function() {
    $(".recognition-send-error-wrapper").children().remove();
  };

  // Will map the results from Tag resource API
  // based on select2 tag data resultsMapping
  // example:
  // data:{
  //  id: "id", // Value of option in this case will be coming from tag.id
  //  text: "name" // Label or Text of option in this case will be from tag.name
  // }

  Post.prototype.processTagOptionsMapping = function(data) {
    var that = this;
    var select2Data = this.$selectElem.data();

    var rootNode = select2Data["rootNode"];
    var mappedData = rootNode ? data[rootNode] : data;
    var resultsMapping = select2Data["resultsMapping"];

    if (resultsMapping) {
      var idMappingKey = resultsMapping.id;
      mappedData = mappedData.map(function(item){
        return {
          id: item[idMappingKey || "id"],
          text: item[resultsMapping.text || "text"]
        };
      }).filter(function(item){
          // Do not show options that have already been selected.
          return !(that.$selectElem.val() || []).includes(item[idMappingKey].toString());
      });
    }

    return {
      results: mappedData
    };
  };

  // This will restructure the select2 tag options
  // for fetching tags from resource API
  Post.prototype.getAsyncSelect2Opts = function() {
    var that = this;
    var select2Data = this.$selectElem.data();
    var select2Options = {
      width: '100%',
      placeholder: (this.isIE !== false && this.isIE < 12) ? '' : this.tagsPlaceholder
    };

    if (select2Data["isAjax"]) {
      select2Options['ajax'] = {
        delay: select2Data["ajaxDelay"] || 250,
        dataType: 'json',
        data: function(params){
          return {
            q: params.term
          };
        },
        processResults: function(data){
          return that.processTagOptionsMapping(data);
        }
      };
    }

    return select2Options;
  };

  Post.prototype.initTagsSelect2 = function() {
    var that = this;

    this.isIE = window.R.utils.isIE();
    this.$selectElem = $('#recognition_tag_ids');

    this.tagsPlaceholder = this.$selectElem.attr('placeholder');
    new window.R.Select2(function () {
      that.$selectElem.select2(that.getAsyncSelect2Opts());
    });
  };

  Post.prototype.setupWysiwygIfRequired = function(wysiwygEnabled, recognitionInputFormat, page) {
    var isEditPage = (page === 'recognitions-edit');
    var inputFormatIsHtml = (recognitionInputFormat === 'html');

    // init wysiwyg if wysiwyg currently enabled for company,
    // or if it is the recognition edit page and the recognition was created via wysiwyg interface
    if (wysiwygEnabled || (isEditPage && inputFormatIsHtml)) {
      var inputFormatOpts = {
        $elem: $('#recognition_input_format'),
        currentFormat: recognitionInputFormat
      };

      R.ui.initWYSIWYG($('#recognition_message'), inputFormatOpts);
      this.wysiwygEditorInitialized = true;
    }
  };

  return Post;
})();
window.R.pages = window.R.pages || {};
// note: the page argument is currently needed for recognition edit page only
["recognitions-edit", "recognitions-create", "recognitions-new_chromeless", "recognitions-new"].forEach(function(page) {
  window.R.pages[page] = function() {
    return new window.R.ui.Post("recognition", { page: page });
  }
});
