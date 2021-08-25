(function() {
  Recognize = Recognize || {};
  Recognize.patterns = Recognize.patterns || {};
  Recognize.patterns.Feed = Feed;

  var timer = 0;
  var counter = 0;
  var CHILD = ".yj-message-actions:not('.recognize-enabed'):not('.recognize-ignore-post')";
  var observers = [];

  function toArray(obj) {
    var array = [];
    // iterate backwards ensuring that length is an UInt32
    for (var i = obj.length >>> 0; i--;) {
      array[i] = obj[i];
    }
    return array;
  }

  function Feed() {
    this.loadStream();

    this.addEvents();

    this.addMutationObservers();
  }

  Feed.prototype.loadStream = function() {
    var $feed = jQuery('.yj-feed-messages');
    counter++;

    if (counter < 50) {
      if ($feed.find(CHILD).children().length > 0) {
        clearTimeout(timer);
        this.init();
        counter = 0;
      } else {
        timer = setTimeout(this.loadStream.bind(this), 500);
      }
    }
  };

  Feed.prototype.addEvents = function() {
    var that = this;
    var scrollTimer = 0;
    var $window = jQuery(window);

    $body.on("click", ".yj-feed-toggle--option, #home-jewel", Recognize.removePraise);
    $body.on('click', '.r-recognize-trigger', this.openRecognitionOverlay.bind(this));
    
    $body.on('click', '.r-approval-trigger', this.setApproval.bind(this));


    jQuery("body > .main-content-container").scroll(function() {
      clearTimeout(scrollTimer);
      scrollTimer = setTimeout(function() {
        that.gatherPostLinks();
        that.addMutationObservers();
      }, 1000);
    })
    .bind('hashchange', function() {
      that.loadStream();
    });

  };
  
  Feed.prototype.setApproval = function(e) {
    var $el = jQuery(e.target);
    
    var post = new Recognize.Post($el.closest('.yj-thread-starter'));
    
    var $approvalElement = post.get$Approval();
    
    var slug = $approvalElement.data("id");
    var approvingRecognition;

    if ($el.hasClass("disabled")) {
      return;
    }

    approvingRecognition = Recognize.patterns.api.post("/recognitions/"+ slug + "/approvals");

    $el.attr("disabled", "disabled").addClass("disabled");

    e.preventDefault();

    approvingRecognition.done(function(data){
      $approvalElement.text(data.approvals_count);
      $el.removeAttr("disabled").removeClass("disabled");
    });

    approvingRecognition.fail(function(data){
      // FIXME: total hack to redirect user to recognition page
      //            if failure.  Reasons for failure:
      //              User may have validated recognition
      //              User may be participant of recognition
      var urlMatch = this.url.match(/(^.*\/)api\/v1\/recognitions\/(.*)\/approvals/);
      window.open(urlMatch[1] + "recognitions/" + urlMatch[2]);
      $el.removeAttr("disabled").removeClass("disabled");
    });
  };

  Feed.prototype.init = function() {
    this.gatherPostLinks();
  };

  Feed.prototype.addMutationObservers = function() {
    var els = document.querySelectorAll(".yj-message-actions");
    els = toArray(els);
    // configuration of the observer:
    var config = { attributes: true, childList: true, characterData: false };
    var that = this;

    if (!window.MutationObserver) {
      return;
    }

    els.forEach(function(el, i) {
      // create an observer instance
      if (observers[i] && observers[i].disconnect) {observers[i].disconnect();}
      observers[i] = new MutationObserver(function(mutations) {
        var $uls = jQuery(".yj-message-actions.recognize-enabed");

        $uls.each(function() {
          var $this = $(this);

          if ($this.find(".recognize-feed-trigger").length === 0) {
            $this.removeClass("recognize-enabed");
            that.addPostAction($this);
          }
        });
      });

      // pass in the target node, as well as the observer options
      observers[i].observe(el, config);
    }.bind(this));
  };

  Feed.prototype.gatherPostLinks = function() {
    var that = this;
    var approvalRecognitions = [];

    jQuery(CHILD).each(function() {
      var post = that.addPostAction(jQuery(this));

      if ( post && post.isRecognition() ) {
        approvalRecognitions.push( post );
      }
    });

    this.addApprovalRecognitions(approvalRecognitions);
  };


  Feed.prototype.addApprovalRecognitions = function(approvalRecognitions) {
    var recognitionIds =[];

    if (approvalRecognitions.length === 0) {
      return;
    }

    approvalRecognitions.forEach(function(post) {
      recognitionIds.push(post.recognitionId());
    });

    var gettingRecognitions = Recognize.patterns.api.get( '/recognitions/search', "slugs="+recognitionIds.join(",") );

    gettingRecognitions.done(function(data) {
      var map = {};

      data.recognitions.forEach(function(recognition) {
        map[recognition.slug] = recognition;
      });

      approvalRecognitions.forEach(function(post) {
        var recognition = map[ post.recognitionId() ];

        if (recognition) {
          var count = recognition.approvals_count;

          var approval_count = count > 0 ? count : "";

          var $approvalLink = post.get$Approval();
          $approvalLink.text( approval_count ).data("id", post.recognitionId());

        }

      });
    });   
  };

  Feed.prototype.addPostAction = function($actions) {
    var className = 'recognize-enabed',
      html = '',
      postTriggerData = {},
      post = new Recognize.Post($actions.closest('.yj-thread-starter'));

    post.approvalRecognitions = [];

    if (post.authorYammerId() === parseFloat(Recognize.yammerID)) {
      $actions.addClass('recognize-ignore-post');
      return;
    }

    if(post.isRecognition()) {
      postTriggerData.klass = 'r-approval-trigger';
      postTriggerData.text = '<strong style="position: relative; bottom: -2px; font-family: arial; font-size: 19px;">+</strong> <span class="recognize-approval"></span>'+ Recognize.patterns.i18n().recognize;
      postTriggerData.title = "Like this recognition";
    } else {
      postTriggerData.klass = 'r-recognize-trigger';
      postTriggerData.text = "★ "+Recognize.patterns.i18n().recognize;
      postTriggerData.title = Recognize.patterns.i18n().recognize;
    }

    if (!$actions.hasClass(className)) {
      html = "<li class='yj-message-action yj-message-action--link yj-message-list-item--action-list-link recognize-feed-trigger'><span class='yj-like-action-wrapper'><a href='javascript://' title='"+postTriggerData.title+"' class='message-action "+postTriggerData.klass+"'>"+postTriggerData.text+"</a></span></li>";
      $actions.addClass(className);

      $actions.find('li:first').after(jQuery(html));
    }

    return post;
  };

  Feed.prototype.openRecognitionOverlay = function(e) {
    var $target = jQuery(e.target), message, yammer_id, yammerThreadUID;

    yammer_id = $target.closest('.yj-thread-starter').find('.yj-byline > .yj-hovercard-link').data('resource-id');
    yammerThreadUID = $target.closest('.yj-thread-list-item').data('thread-id');    
    post = new Recognize.Post($target.closest('.yj-message-container'));

    Recognize.patterns.recognitionForm.open(yammer_id, post.text());
  };
})();
