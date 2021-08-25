(function() {
  var finalSet;

  var baseSet = {
    "recognize": "Recognise",
    "stats": "Stats",
    "company_admin": "Company Admin",
    "send_recognition": "Send Recognition",
    "sign_in": "Sign In to Recognize",
    "loading": "Loading...",
    "profile": "Profile",
    "stream": "Stream",
    "reconnect": "Connect"
  };

  var fullSet = {
    "en-US": function() {
      var thisSet = baseSet;
      thisSet.recognize = "Recognize";
      return thisSet;
    },
    "fr": {
      "recognize": "Reconnaissance",
      "stats": "Statistiques",
      "company_admin": "Bilan de l'enterprise",
      "send_recognition": "Envoyer",
      "sign_in": "Ouvrir une session",
      "loading": "Chargement",
      "profile": "Profil",
      "stream": "Stream",
      "reconnect": "Connect"
    },
    "es": {
      "recognize": "Recognize",
      "stats": "Estadísticas",
      "company_admin": "Administrador",
      "send_recognition": "Enviar Elogios",
      "sign_in": "Registrarse",
      "loading": "Cargando",
      "profile": "Perfil",
      "stream": "Stream",
      "reconnect": "Connect"
    }
  };

  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.i18n = function() {
    var languageSet;
    var browserLanguage = navigator.language ? navigator.language : navigator.userLanguage;
    browserLanguage = browserLanguage || "en";

    if (finalSet) {
      if (typeof finalSet === "function") {
        return finalSet();
      } else {
        return finalSet;
      }
    }

    for (languageSet in fullSet) {
      if (!fullSet.hasOwnProperty(languageSet)) {
        return;
      }

      if (browserLanguage.toLowerCase().indexOf(languageSet.toLowerCase()) > -1) {
        finalSet = fullSet[languageSet];
      }
    }

    finalSet = !finalSet ? baseSet : finalSet;

    if (typeof finalSet === "function") {
      return finalSet();
    } else {
      return finalSet;
    }
  };

})();