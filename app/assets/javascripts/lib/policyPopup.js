window.R = window.R || {};

window.R.policyPopup = (function($, window, body, R, undefined) {

  function policyPopup() {
    var uid = $body.data("uid");

    if (window.localStorage["recognizePolicyAccepted"]) {
      return;
    }

    if (uid) {
      $.ajax("/cookie-policy-check", {
        action: "get",
        data: uid,
        success: function(e, data) {
          if (!data.accepted) {
            showPolicyPopup();
          }
        }
      });
    } else {
      showPolicyPopup();
    }

  }

  function showPolicyPopup() {
    $(function() {
      $(document.body).append(getHTMLContent());
      addEvents();
    });
  }

  function addEvents() {
    $document.on(R.touchEvent, "#policy-actions", setPolicyAccepted);
  }

  function getHTMLContent() {

    var html = "<div id='policyPopup'>";
    html += "<p>We use cookies to keep you logged into Recognize and anonymously see how people use Recognize to improve the experience. By continuing to use Recognize, you accept our use of <a href='/cookies'>cookies</a>, our <a href='/terms'>Terms of Service</a>, and <a href='/privacy'>Privacy Policy</a>.</p>";

    html += '<div class="policy-actions"><a href="/user-rights">More information</a>';
    html += '<a href="javascript://" id="cookie-accept" class="button">I accept</a></div></div>';

    return html;
  }

  function setPolicyAccepted() {
    window.localStorage["recognizePolicyAccepted"] = true;

    $.ajax("/cookie-policy-check", {
      action: "post",
      data: "accepted-policy"
    });

    $("#policyPopup").hide();
    $document.off(R.touchEvent, "#policy-actions", setPolicyAccepted);
  }

  //policyPopup();

  return policyPopup;

})(jQuery, window, document.body, window.R);