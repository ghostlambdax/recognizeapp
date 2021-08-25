(function() {
  'use strict';

  if (!window.location.origin) {
    window.location.origin = window.location.protocol + "//" + window.location.hostname + (window.location.port ? ':' + window.location.port: '');
  }

  window.R = window.R || {};

  window.R.utils = {
    isFullscreen: function() { return window.location.href.indexOf("/grid") !== -1; },
    isIE: function() {
      var ua = window.navigator.userAgent;

      // Test values; Uncomment to check result …

      // IE 10
      // ua = 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0)';

      // IE 11
      // ua = 'Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko';

      // Edge 12 (Spartan)
      // ua = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36 Edge/12.0';

      // Edge 13
      // ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Safari/537.36 Edge/13.10586';

      var msie = ua.indexOf('MSIE ');
      if (msie > 0) {
        // IE 10 or older => return version number
        return parseInt(ua.substring(msie + 5, ua.indexOf('.', msie)), 10);
      }

      var trident = ua.indexOf('Trident/');
      if (trident > 0) {
        // IE 11 => return version number
        var rv = ua.indexOf('rv:');
        return parseInt(ua.substring(rv + 3, ua.indexOf('.', rv)), 10);
      }

      var edge = ua.indexOf('Edge/');
      if (edge > 0) {
        // Edge (IE 12+) => return version number
        return parseInt(ua.substring(edge + 5, ua.indexOf('.', edge)), 10);
      }

      // other browser
      return false;
    },

    pingSignInPopup: function(callback, popup) {
      var that = this;

      var interval = setInterval(function() {
        console.log("ping", window.location.origin);
        popup.postMessage("Recognize wants to login in please", window.R.host);
      }, 1000);

      // TODO: ensure right domain for receiving/sending message.
      // TODO turn off event listener once hit.
      window.addEventListener("message", function(e) {
        if (e.origin === window.R.host) {
          console.log("message received", "logging in!!!!!!!");
          callback(arguments);
          clearInterval(interval);
        }
      }.bind(this), false);
    },

    checkLoginStatus: function(callback, opts, popup) {
      var data = {}, that = this, loginInterval;
      opts = opts || {};

      if (window.Office) {
        return opts.response.value.addEventHandler(Microsoft.Office.WebExtension.EventType.DialogMessageReceived, function () {
          callback();
        });
      }

      if (popup && !this.isIE()) {
        this.pingSignInPopup(amILoggedIn, popup);
      } else {
        loginInterval = setInterval(amILoggedIn, 2500);
      }

      function amILoggedIn() {

        jQuery.ajax({
          url: "/api/auth_status",
          beforeSend: function (xhr) { xhr.setRequestHeader('X-Recognize-Referrer', window.location.href); }, // for debugging
          dataType: "json"
        }).done(function (responseData) {

          if (responseData.status === "true" || responseData.status === true) {
            if (loginInterval) clearInterval(loginInterval);
            callback();
          }
        });
      }
    },

    openWindow: function(url, width, height, callback) {
      var popup, status;
      width = width || 1024;
      height = height || 768;

      console.log("url", url);

      if (window.Office) {
        popup = Office.context.ui.displayDialogAsync(url,
          {height: 90, width: 55, requireHTTPS: true},
          function (result) {
            if (callback) callback(result);
          });
      } else {
        popup = window.open(url, '_blank', 'location=yes,height='+height+',width='+width+',scrollbars=yes,status=yes');
        if (popup) {
          status = "succeeded";
        } else {
          status = "failed";
        }

        if (callback) callback({value: popup, status: status});
      }

      return popup;
    },

    getFile : function(file, callback) {
      var that = this;
      $.ajax({
        url: file,
        dataType: "html",
        success: function(data) {
            callback.apply(that, [data]);
        },
        cache: false
      });
    },

    render : function(data, template, callback) {
      this.getFile(template, function(file) {
        var hbTemplate = Handlebars.compile(file);
        callback(hbTemplate(data));
      });
    },

    queryParams: function(callback, url) {
      var searchStr = url || window.location.search;
      if(typeof searchStr === "undefined" ||  searchStr === "" || searchStr.indexOf('?') == -1) {
        return {};
      }

      var obj = this.paramStringToObject(searchStr.slice(searchStr.indexOf('?') + 1), callback);
      return obj;
    },

    addParamsToUrlString: function(url, paramsObj, URIEncode) {
      var newParamsObj = {};
      var existingParamsObj;

      if (url.indexOf("?") > -1) {
        existingParamsObj = window.R.utils.queryParams(null, url);
      } else {
        existingParamsObj = {};
      }

      // Add new keys
      for (var key in paramsObj) {
        existingParamsObj[key] = paramsObj[key];
      }


      // Remove all params from URL string
      if (url.indexOf("?") > -1) {
        url = url.substring(0, url.indexOf("?"));
      }

      // Add new combined set of params
      url = url + "?" + window.R.utils.objectToParamString(existingParamsObj, URIEncode);

      return url;
    },

    locationWithNewParams: function(params) {
      var queryObj, url;

      if (typeof(params) === "string") {
        params = this.paramStringToObject(params);
      }

      queryObj = window.R.utils.queryParams();
      for(var key in params) {
        queryObj[key] = params[key];
      }
      var queryParams = $.param(queryObj);

      url = window.location.pathname + "?" + queryParams;

      if(window.location.hash !== "") {
        url += window.location.hash;
      }

      // window.location = url;
      return url;

    },

    guid: function() {
      return (S4() + S4() + "-" + S4() + "-4" + S4().substr(0,3) + "-" + S4() + "-" + S4() + S4() + S4()).toLowerCase();
    },

    paramStringToObject: function(paramString, callback) {
      // PETE - 2015-06-10
      // This algorithm is pretty terrible, as I'm starting to hack it up
      // We should probably look to replace this
      var obj = {},
            hashes = decodeURIComponent(paramString).split('&');

      for(var i = 0; i < hashes.length; i++)
      {
          // split on = but not == because of base64
          // TODO: there has to be a better way, but because of the 2nd '='
          // character negation class, the first letter of value will go away
          // with the split, so i bring it back by wrapping it in a group
          // and join it up later
          var paramArray = hashes[i].split(/=([^=])/);

          if(paramArray[1]) { // if there is a value
            paramArray = [paramArray[0], paramArray[1]+paramArray[2]];
          } else {
            paramArray = [paramArray[0].split(/=/)[0], ""];
          }

          if(callback) {
            paramArray = callback(paramArray[0], paramArray[1]);
          }
          obj[paramArray[0]] = paramArray[1];
      }
      return obj;
    },

    objectToParamString: function(obj, URIEncode) {
        var toEncode = URIEncode === true || URIEncode === undefined ? true : false;

        return Object.keys(obj).map(function(key) {
                var value;

                if (toEncode) {
                    value = encodeURIComponent(key) + '=' +
                        encodeURIComponent(obj[key]);
                } else {
                    value = key + '=' + obj[key];
                }

                return value;


            }).join('&');
    },

    inherits: function(subClass, superClass) {
      var F = function() {};

      if (!superClass) {return;}

      F.prototype = superClass.prototype;
      subClass.prototype = new F();
      subClass.prototype.constructor = subClass;

      subClass.superclass = superClass.prototype;
      if (superClass.prototype.constructor === Object.prototype.constructor) {
        superClass.prototype.constructor = superClass;
      }
    },

    // Deprecated or can we still use this?
    installFirefox: function(e) {
      var el = e.target;
      var params;
      e.preventDefault();

      params = {
        "Recognize": {
          URL: el.href,
          IconURL: el.getAttribute("data-iconURL"),
          toString: function () { return this.URL; }
        }
      };

      InstallTrigger.install(params);

      return false;
    },

    createDataTable: function(columns, $table, options) {
      var that = this;
      var dataTable;

      var dataTableLanguages = {
        'es': '//cdn.datatables.net/plug-ins/1.10.21/i18n/Spanish.json',
        'fr': '//cdn.datatables.net/plug-ins/1.10.21/i18n/French.json',
        'fr-CA': '//cdn.datatables.net/plug-ins/1.10.21/i18n/French.json',
        'ar': '//cdn.datatables.net/plug-ins/1.10.21/i18n/Arabic.json',
        'zh-TW': {
          "processing": "處理中...",
          "loadingRecords": "載入中...",
          "lengthMenu": "顯示 _MENU_ 項結果",
          "zeroRecords": "沒有符合的結果",
          "info": "顯示第 _START_ 至 _END_ 項結果，共 _TOTAL_ 項",
          "infoEmpty": "顯示第 0 至 0 項結果，共 0 項",
          "infoFiltered": "(從 _MAX_ 項結果中過濾)",
          "infoPostFix": "",
          "search": "搜尋:",
          "paginate": {
            "first": "第一頁",
            "previous": "上一頁",
            "next": "下一頁",
            "last": "最後一頁"
          },
          "aria": {
            "sortAscending": ": 升冪排列",
            "sortDescending": ": 降冪排列"
          }
        }
      };
      var language = dataTableLanguages[$html.attr('lang')];

      options = options || {};
      options.order = options.order || [[1, "asc"], [2, "asc"], [3, "asc"]];

      this.dataTableTimer = this.dataTableTimer || 0;

      if ($table.constructor === String) {
        $table = $($table);
      }

      if ($table.length) {
        clearTimeout(this.dataTableTimer);

        var dtOpts = {
          ordering: true,
          paging: true,
          searching: options.searching || true,
          responsive: false,
          pageLength: 25,
          serverSide: true,
          processing: true,
          createdRow: options.createdRow,
          "columns": columns,
          ajax: {
            url: (options.url || $table.data('endpoint') || $table.data('source')),
            data: options.ajaxData
          },
          "order": options.order,
          stateDuration: 0
        };

        if (language) {
          if (typeof language === 'string') {
            dtOpts.language = {
              url: language
            };
          } else {
            dtOpts.language = language;
          }
        }

        if (options.hasOwnProperty('searching')) {
          dtOpts.searching = options.searching;
        }

        if (options.hasOwnProperty('paging')) {
          dtOpts.paging = options.paging;
        }

        if (options.dataSrc) {
          dtOpts.dataSrc = options.dataSrc;
        }

        if (options.dom) {
          dtOpts.dom = options.dom;
        }

        if(options.order) {
          dtOpts.order = options.order;
        }

        if(options.drawCallback) {
          dtOpts.drawCallback = options.drawCallback;
        }

        if(options.lengthMenu) {
          dtOpts.lengthMenu = options.lengthMenu;
        } else {
          var vals = [25, 50, 100, 250];
          var labels = vals.slice();
          if (options.includeAllOptionInLengthMenu) {
            vals.push(-1);
            labels.push('All');
          }
          dtOpts.lengthMenu = [ vals, labels ];
        }

        if(options.rowGroup) {
          dtOpts.rowGroup = options.rowGroup;
        }

        // Expected `colvis` attribute's signature:
        // {
        //    enabled: <boolean>,
        //    insertButtonBeforeSelector: <css selector>,
        //    columnsToShowByDefault: <array of column names to be shown before colvis kicks in>
        // }
        if(options.colvis && options.colvis.enabled) {
          dtOpts = $.extend(true, dtOpts, that.getColVisStateSaveDatatablesOptions(columns));

          if(options.colvis.columnsToShowByDefault) {
            // Only show certain columns by default. User however can toggle the visibility using the colvis toggler.
            // User's preference of the column visibilities is persisted in browsers local storage. The colvis state
            // stored in local storage overrides these explicit default column visibility settings.
            dtOpts.columns = columns.map(function(column){
              var columnShouldBeHidden = options.colvis.columnsToShowByDefault.indexOf(column.data) === -1;
              if (columnShouldBeHidden) {
                column.visible = false;
              }
              return column;
            });
          }

          // Property `autoWidth` is by default `true` for a DataTable. However, for datatables with colvis support, to
          // get columns (and table) width to work gracefully on `page:restore`, `autoWidth` needs to be turned off.
          dtOpts.autoWidth = options.autoWidth || false;

          /*
           * This colvis setup needs to be wrapped in initComplete callback to make it work for languages setup with remote URL
           * Otherwise, it fires too early - before the insertButtonBeforeSelector container is loaded -
           *   which is loaded after the request for the language file is complete
           **/
          dtOpts.initComplete = function () {
            var $colvisButton = $('a.dt-button.buttons-collection.buttons-colvis');
            if($colvisButton.length === 0){
              that.bindColVisButton(dataTable, $(options.colvis.insertButtonBeforeSelector));
              that.updateColvisCount(this);
            }
          };
        }

        // add processing class to datatable to show overlay
        // un-delegation apparently not needed
        var processingClass = 'dt-processing';
        $table.on( 'processing.dt', function ( _e, _settings, processing ) {
          var action = processing ? 'addClass' : 'removeClass';
          $table[action](processingClass);
        });
        $table.on( 'preInit.dt', function () { // needed for initial phase
          $table.addClass(processingClass);
        });

        dataTable = $table.DataTable(dtOpts);

        //filtering delay for bug due to response data size
        $table.dataTable().fnSetFilteringDelay();

        if (options.useButtons) {
          var exportButtons;
          if(options.exportOptions){
            var buttonOpts = {
              buttons: [
                $.extend( true, {}, options.exportOptions, {
                  extend: 'copy'
                } ),
                $.extend( true, {}, options.exportOptions, {
                  extend: 'csv'
                } ),
                $.extend( true, {}, options.exportOptions, {
                  extend: 'excelHtml5'
                } ),
                $.extend( true, {}, options.exportOptions, {
                  extend: 'pdf'
                } ),
                $.extend( true, {}, options.exportOptions, {
                  extend: 'print'
                } )]
            }
            exportButtons = new $.fn.dataTable.Buttons( dataTable, buttonOpts);
          } else {
            exportButtons = new $.fn.dataTable.Buttons( dataTable, {
              buttons: ['copy', 'csv', 'excelHtml5', 'pdf', 'print']
            });
          }
          exportButtons.container().insertAfter( $(options.insertButtonsAfterSelector ) );
        } else if(options.serverSideExport) {

          // options = $.extend(true, options, options.serverSideExport);
          exportButtons = new $.fn.dataTable.Buttons( dataTable, {buttons: options.serverSideExport.buttons});
          exportButtons.container().insertAfter( $(options.serverSideExport.insertButtonsAfterSelector ) );
        }

      } else {
        this.dataTableTimer = setTimeout(function() {
          that.createDataTable(columns, $table);
        }, 500);
      }

      return dataTable;
    },
    bindColVisButton: function(dataTable, insertBeforeSelector) {
      var colVisButton = new $.fn.dataTable.Buttons( dataTable, {
        buttons: [
          {
            titleAttr: 'Toggle column visibility',
            text: "<div id='colvis-icon-wrapper'></div><span id='colvis-hidden-col-count' class='smallPrint'></span>",
            extend: 'colvis',
            // Exclude those that are hardcoded to be invisible in  respective *_datatable.rb. An example is completed_tasks_datatable's date column, which is massaged while rowGroup-ing.
            columns: ":not([data-visible='false'])"
          }
        ]
      });
      colVisButton.container().insertBefore(insertBeforeSelector);
      // Since the initComplete(:441) callback fires late, tooltip needs to
      // be manually initialized for the colvis button.
      colVisButton.container().children().tooltip();
    },
    getColVisStateSaveDatatablesOptions: function(columns) {
      var opts =  {};
      opts.stateSave = true;
      var that = this;

      // Only save states of `columns` and `time`; `time` is apparently needed to write to localstorage.
      var propertiesToStateSave = ["time", "columns"];

      // See https://datatables.net/reference/option/stateSaveCallback,
      // The `data` given to the function `stateSaveParams` represents state of the current datatable. For instance:
      // {
      //   "time":   {number}               // Time stamp of when the object was created
      //   "start":  {number}               // Display start point
      //   "length": {number}               // Page length
      //   "order":  {array}                // 2D array of column ordering information (see `order` option)
      //   "search": {
      //   "search":          {string}  // Search term
      //   "regex":           {boolean} // Indicate if the search term should be treated as regex or not
      //   "smart":           {boolean} // Flag to enable DataTables smart search
      //   "caseInsensitive": {boolean} // Case insensitive flag
      // },
      //   "columns" [
      //     {
      //       "visible": {boolean}     // Column visibility
      //       "search":  {}            // Object containing column search information. Same structure as `search` above
      //     }
      //     ]
      // }
      // We discard state properties that we don't want saved.
      opts.stateSaveParams =  function(settings, data) {
        // BEGIN - only save states of column visibility; discard state properties that need not be saved.
        Object.keys(data)
          .forEach(function(property) {
            if (propertiesToStateSave.indexOf(property) === -1) {
              delete data[property];
            }
          });
        data.columns.forEach(function(column){
          Object.keys(column).forEach(function(property){
            if (property !== "visible") {
              // discard all properties but `visible`
              delete column[property];
            }
          });
        });
        // END - only save states of column visibility; discard state properties that need not be saved.

        that.updateColvisCount(this);
      };
      return opts;
    },
    // updates count of hidden columns beside colVis button
    updateColvisCount: function(datatable) {
      var hiddenColCount = datatable.api().table().columns(':not([data-visible="false"]):not(":visible")').count();
      $("#colvis-hidden-col-count").html( hiddenColCount === 0 ? "" : hiddenColCount);
    },
    redrawDatatable: function($table) {
      var dt = $table.DataTable();
      dt.draw(); // will reload ajax
      window.recognize.patterns.formLoading.resetButton();
    },
    interval_conversion_factor: function(from, to) {
      //requires gon.intervals and gon.interval_conversion_map to be loaded in controller
      if(from === to) {
        return 1;
      } else if(from > to ) {
        return gon.interval_conversion_map[from][to];
      } else {
        return -1 * gon.interval_conversion_map[to][from];
      }
    },
    getCurrencyPrefix: function() {
      //requires gon.currency to be loaded in controller
      return gon.currency;
    },
    //
    // Formats a number to currency format.
    // opts:
    //  includeSymbol - true by default.
    //
    formatCurrency: function(num, opts) {
      opts = opts || {};
      var includeSymbol = opts.includeSymbol === undefined ? true : opts.includeSymbol;

      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toLocaleString
      // Use of `minimumFactionDigits: 2` ensures there is always atleast 2 digits after decimal in locale'd string.
      // This is those `num` that have less than 2 digits after decimal.
      // For eg: parseFloat((12.1).toFixed(2)) = 12.1, but we need 12.10
      var val = (parseFloat(num.toFixed(2))).toLocaleString(undefined, {minimumFractionDigits: 2});

      //if only zeroes after decimal, get rid of them
      val = val.replace(/\.00?$/, '');

      if (includeSymbol) {
        val = this.getCurrencyPrefix() + val;
      }
      return val;
    },
    listenForWindowMessage: function(){
      // For logging in from iframe / Sharepoint
      window.addEventListener("message", function(event) {
        if (event.origin === window.R.host && event.data === "Recognize wants to login in please") {
          event.source.postMessage("Logging in", event.origin);
        }
      }, false);

    },
    l: function(key) {
      // localization stub
      var lookup = {'dict.confirm': 'Confirm', 'dict.cancel': 'Cancel', 'dict.submit': 'Submit'};
      return lookup[key] || key;
    },
    remoteSwal: function(userOpts) {
      var defaultOpts = {
        html: "<img src='/assets/icons/ajax-loader.gif'>",
        showCancelButton: true,
        reverseButtons: true,
        confirmButtonText: window.R.utils.l('dict.submit'),
        cancelButtonText: window.R.utils.l('dict.cancel')
      };
      var opts = $.extend(userOpts, defaultOpts);
      return Swal.fire(opts);
    },
    // prevents infiniteScroll page scroll binding from carrying on to other pages with Turbolinks
    destroyInfiniteScroll: function ($elem) {
      if ($elem && $elem.data('infiniteScroll')) {
        $elem.infiniteScroll('destroy');
        // fully clear the data as well: stackoverflow.com/a/11151931
        $elem.data('infiniteScroll', null);
      }
    },
    getSelectedLabelsFromSelect: function($select) {
      var selectedOptions = $select.find("option:selected");
      return $.map(selectedOptions, function(item, i){return item.text;});
    },
    isLoggedInLayout: function() {
      return $("body").data('loggedin') ? true : false;
    },
    resetCaptcha: function() {
      if(typeof(grecaptcha) != 'undefined') {
        try{
          grecaptcha.reset();
        } catch(e) {
          console.error(e);
        }
      }
    },

    // Initializes a select2 component after succesful remote data fetch via ajax.
    // Can be used in scenarios where you need to prepopulate the select2 component before initializing
    // or in scenarios where standard select2 remote data fetching is not ideal.
    // For more on its genesis: https://github.com/Recognize/recognize/pull/3197#discussion_r464739011
    select2RemoteSingleton: function(endpoint, selectWrapper, ajaxOpts){
      ajaxOpts = {} || ajaxOpts;
      return new Promise(function(resolve, reject) {
        var $selectWrapper= $(selectWrapper);
        var $ajaxSpinner = $selectWrapper.find(ajaxOpts["ajaxSpinnerSelector"] || ".ajax-loader");
        var $warningMessageContainer = $selectWrapper.find(ajaxOpts["warningMessageContainerSelector"] || ".warning");
        var defaultAjaxOpts = {
          url: endpoint,
          type: 'GET',
          dataType: 'json',
          beforeSend: function(){
            $warningMessageContainer.empty();
            $ajaxSpinner.show();
          },
          success: function(data) {
            new window.R.Select2(function() {
              resolve(data);
            });
          },
          error: function(xhr){
            reject(xhr);
          },
          complete: function(){
            $ajaxSpinner.hide();
          }
        };
        ajaxOpts = $.extend({}, defaultAjaxOpts, ajaxOpts);
        $.ajax(ajaxOpts);
      });
    },

    // This is for requests throttled by Rack::Attack
    setThrottledErrorIfNeeded: function(xhr) {
      if (xhr.status !== 429) return;

      var message = 'Too many requests, please try again';

      var retryAfter = xhr.getResponseHeader('retry-after');
      if (retryAfter)
        message += ' ' + retryAfter + ' seconds later.';

      xhr.responseJSON = {
        type: 'error',
        errors: {base: [message]}
      };
    },

    safe_feather_replace: function() {
      if (typeof feather !== 'undefined')
        feather.replace();
    }

  };

  function S4() {
    return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
  }
})();
