window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["recognitions-show"] = (function() {
  
  var Show = function() {
    var timer = 0;
    var $recognitionSignup = $("#recognition-show-signup");
    
    $body.on("click", "#recognition-access-wrapper.access-enabled", togglePrivacy);
    $body.on("click", "#sharing.access-enabled a", makePagePublic);

    $body.on(R.touchEvent, ".recognition-delete .button", function(){
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
      }).then(function(result) {
        if (result.value) {
          $(".recognition-delete").submit();
        }
      });
      return false;
    });

    $body.on(R.touchEvent, ".recognition-award-certificate", function(e) {
      e.preventDefault();
      e.stopPropagation();
      var linkGenerator = AwardLinkGenerator();
      linkGenerator.openPopup();
    });

    (function changeYammerText() {
      var $el = $(".yj-publisher-watermark");
      if ($el.length) {
        $el.text("Leave a comment");
        return clearTimeout(timer);
      }
      timer = setTimeout(changeYammerText, 50);
    })();
    
    if ( $recognitionSignup.length > 0 ) {
      $recognitionSignup.find(".close-icon").click(function(e) {
        $recognitionSignup.parent().children().removeClass('bg-blur');
        e.preventDefault();
        $recognitionSignup.addClass("closed");
      });
    }
    this.comments = new R.Comments();
    goToAnchorIfItIsThere();
  };
  
  function makePagePublic() {
    setAccess(true);
  }
  
  function togglePrivacy() {
    setAccess();
  }

  function goToAnchorIfItIsThere() {
    var hash = window.location.hash, offset, fixed_header_height;

    if (!hash.length) {
      return;
    }

    offset = $(hash).offset().top;
    fixed_header_height = 65;

    $("html, body").animate({
        scrollTop: (offset - fixed_header_height - 2) +"px"
      },
      1000
    );
  }

  function setAccess(makePublic) {
    var $accessWrapper = $("#recognition-access-wrapper");
    var network = $body.data("name");

    var ajaxMetaData = {
      url: "/"+network+"/recognitions/"+$accessWrapper.data('param')+"/toggle_privacy",
      type: "PUT",
      beforeSend: function(xhr, settings){
        xhr.setRequestHeader('accept', '*/*;q=0.5, ' + settings.accepts.script);
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      }          
    };

    if (makePublic) {
      $accessWrapper.removeClass("private");
      ajaxMetaData.data = {make_public: makePublic};
      $("#sharing").show();
    } else {
      $accessWrapper.toggleClass("private");
    }
        
    $.ajax(ajaxMetaData);
  }

  function AwardLinkGenerator() {
    var linkGenerator = function() {
      $body.on('change', '#award-certificate-recipient', function() {
        var disabled = (this.value === '');
        $('.swal2-actions .swal2-confirm').attr('disabled', disabled);
      });
    };

    linkGenerator.prototype.openPopup = function() {
      var awardForm = this.generateRecipientSelectionForm();
      var that = this;
      Swal.fire({
        title: gon.recognition.award_recipient_title,
        html: awardForm,
        showCancelButton: true,
        confirmButtonText: gon.recognition.view,
        closeOnConfirm: false,
        onOpen: function() {
          $('.swal2-actions .swal2-confirm').attr('disabled', 'disabled');
        },
      }).then(function(result) {
        if(result.value) {
          var selectedRecipientSlug = $('#award-certificate-recipient')[0].value;
          that.generateAwardLinkForRecipientAndOpen(selectedRecipientSlug);
        }
      });
    };

    linkGenerator.prototype.generateRecipientSelectionForm = function() {
      var recipientData = {
        recipients: gon.recognition.recipients_data,
        selectUser: gon.recognition.select_user
      };
      var recipientTemplate = Handlebars.compile( $('#recipient-select-template').html() );
      return recipientTemplate(recipientData);
    };

    linkGenerator.prototype.generateAwardLinkForRecipientAndOpen = function(recipientWithId) {
      var $awardCertLink = $('#view-certificate-link').first();
      recipientWithId = recipientWithId.split(':');
      var certificateUrl = window.R.utils.addParamsToUrlString($awardCertLink.attr('href'), { recipient: recipientWithId[1], recipient_type: recipientWithId[0] });
      window.open(certificateUrl, '_blank');
    };

    return new linkGenerator();
  }

  return Show;

})();