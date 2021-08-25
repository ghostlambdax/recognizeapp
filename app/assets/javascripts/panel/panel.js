(function(){
  'use strict';

  var item;

  var $form;


  window.R = window.R || {};
  window.R.outlookPanel = function() {
    jQuery(document).ready(function() {

      if ($.fn.tooltip) {
          $("[title]").tooltip({
              placement: "bottom",
              delay: 500
          });
      }

      $document.on("blur", "#recognition_message", captureRecipients);
      $document.on(R.touchEvent, "#badge-trigger", function() {
        R.transition.slide("#new-recognition", "#badges-wrapper");
        captureRecipients();
      });

      $document.on(R.touchEvent, ".badge-item", selectBadge);
      $document.on("ajax:beforeSend", "#new_recognition", beforeSend);
      $document.on("ajax:success", "#new_recognition", composeMessage);
      $document.on("ajax:error", "#new_recognition", error);

      setInterval(captureRecipients, 2000);
    });

    if (!window.R.ajaxify) {
      window.R.ajaxify = new window.R.Ajaxify();
    }
  };

  // The initialize function must be run each time a new page is loaded
  if (window.Office) {
      Office.initialize = function(reason) {
          window.R.outlookPanel();
      };
  }

  function captureRecipients() {
    getRecipients(function(recipient) {
      R.post.addRecepient({
        email: recipient.emailAddress,
        name: recipient.displayName,
        avatar_thumb_url: null,
        type: recipient.recipientType
      });
    });
  }

  function error() {
    $form.removeClass("loading");
  }

  function beforeSend() {
    $form = $("#new_recognition");
    $form.addClass("loading");
  }

  function composeMessage(e, data) {
    var $form = $("#new_recognition"), message, item;

    $("#recognition-link").attr("href", data.recognition.permalink);

    if (!data.recognition.requires_approval) {
      message = createMessage({
        message: data.recognition.message_plain,
        link: data.recognition.permalink,
        badge: {
          url: $("#badge-trigger img").attr("src"),
          title: $("#badge-name").text()
        }
      });
      item = Office.cast.item.toItemCompose(Office.context.mailbox.item);
      item.body.setSelectedDataAsync(message,
        {coercionType: Office.CoercionType.Html});
    }

    $form.removeClass("loading");
    R.transition.slide("#new-recognition", "#complete-recognition");
  }

  function createMessage(recognitionData) {
    return Handlebars.compile( $("#panelMessage").html() )(recognitionData); // Compile returns a function and then we pass in the data to that.
  }

  function selectBadge(e) {
    R.transition.slide("#badges-wrapper", "#new-recognition", "reverse");
  }

  function setSubject(subject){
    Office.cast.item.toItemCompose(Office.context.mailbox.item).subject.setAsync(subject);
  }

  function getSubject(){
    Office.cast.item.toItemCompose(Office.context.mailbox.item).subject.getAsync(function(result){
      app.showNotification('The current subject is', result.value);
    });
  }

  function getRecipients(callback) {
    item = Office.context.mailbox.item;
    // Local objects to point to recipients of either
    // the appointment or message that is being composed.
    // bccRecipients applies to only messages, not appointments.
    var toRecipients, ccRecipients, bccRecipients;
    // Verify if the composed item is an appointment or message.
    if (item.itemType == Office.MailboxEnums.ItemType.Appointment) {
      toRecipients = item.requiredAttendees;
      ccRecipients = item.optionalAttendees;
    }
    else {
      toRecipients = item.to;
      ccRecipients = item.cc;
      bccRecipients = item.bcc;
    }

    // Use asynchronous method getAsync to get each type of recipients
    // of the composed item. Each time, this example passes an anonymous
    // callback function that doesn't take any parameters.
    toRecipients.getAsync(function (asyncResult) {

      if (asyncResult.status == Office.AsyncResultStatus.Failed){
        write(asyncResult.error.message);
      }
      else {
        // Async call to get to-recipients of the item completed.
        // Display the email addresses of the to-recipients.
        //write ('To-recipients of the item:');
        if (asyncResult && callback) {
          asyncResult.value.forEach(function(recipient) {
            callback(recipient);
          });

        }

      }
    }); // End getAsync for to-recipients.

    // Get any cc-recipients.
    ccRecipients.getAsync(function (asyncResult) {
      if (asyncResult.status == Office.AsyncResultStatus.Failed){
        write(asyncResult.error.message);
      }
      else {
        // Async call to get cc-recipients of the item completed.
        // Display the email addresses of the cc-recipients.
        //write ('Cc-recipients of the item:');
      }
    }); // End getAsync for cc-recipients.

    // If the item has the bcc field, i.e., item is message,
    // get any bcc-recipients.
    if (bccRecipients) {
      bccRecipients.getAsync(function (asyncResult) {
        if (asyncResult.status == Office.AsyncResultStatus.Failed){
          write(asyncResult.error.message);
        }
        else {
          // Async call to get bcc-recipients of the item completed.
          // Display the email addresses of the bcc-recipients.
          //write ('Bcc-recipients of the item:');
        }

      }); // End getAsync for bcc-recipients.
    }
  }

  function addToRecipients(){
    var item = Office.context.mailbox.item;
    var addressToAdd = {
      displayName: Office.context.mailbox.userProfile.displayName,
      emailAddress: Office.context.mailbox.userProfile.emailAddress
    };

    if (item.itemType === Office.MailboxEnums.ItemType.Message) {
      Office.cast.item.toMessageCompose(item).to.addAsync([addressToAdd]);
    } else if (item.itemType === Office.MailboxEnums.ItemType.Appointment) {
      Office.cast.item.toAppointmentCompose(item).requiredAttendees.addAsync([addressToAdd]);
    }
  }

  // Recipients are in an array of EmailAddressDetails
// objects passed in asyncResult.value.
  function displayAddresses (asyncResult) {
    for (var i=0; i<asyncResult.value.length; i++)
      write (asyncResult.value[i].emailAddress);
  }

// Writes to a div with id='message' on the page.
  function write(message){
    var recipientEl = document.getElementById('recipient-wrapper');
    if (recipientEl) {recipientEl.innerText += message;}
  }
})();
