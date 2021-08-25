window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["identity_providers-show"] = (function() {
  var S = function() {
    this.links = ".identity-providers .list-subtle-border .button";
    this.addEvents();
  };

  // TODO: Localize

  S.prototype.auth = function(e) {
    var $this = $(this),
        popup,
        href = $this.prop("href"),
        params = R.utils.queryParams(null, href),
        redirect = params["redirect"] || (params["viewer"] ? "/?viewer="+params["viewer"] : "/"),
        htmlPopup = '<h3>Logging in to Recognize</h3>';

    e.preventDefault();

    function openPopup() {
      Swal.fire({
        html: htmlPopup,
        showConfirmButton: false
      });

      popup = R.utils.openWindow(href, 520, 570, function (response) {

        R.utils.checkLoginStatus(function() {
          window.location = redirect;
        }, {network: params["network"], referrer: redirect}, response.value);

        if (response.status === "failed") {
          Swal.fire({
            html: '<h3>The popup is not opening</h3><p>Please ensure popups are enabled.</p> <a class="button button-primary open-popup" href="javascript://">Try again</a>',
            showConfirmButton: false
          });
        }
      });
    }

    $document.on(R.touchEvent, ".open-popup", function() {
      openPopup();
      Swal.close();
    });

    openPopup();
  };

  S.prototype.addEvents = function() {

    if (window.location.href.indexOf("sharepoint") > -1 && window.location.href.indexOf("viewer") > -1) {
      $document.on(R.touchEvent, this.links, this.auth);
    }
  };
  S.prototype.removeEvents = function() {
    $document.off(R.touchEvent, this.links, this.auth);
    $document.off(R.touchEvent, ".openPopup");
  };

  return S;
})();