/*


   )..(
   (.o)
 `.(  )
   ||||    LitaTables
   "`'"
*/

(function(){
  'use strict';


  window.R = window.R || {};

  // Removing existing litatables on before caching
  $document.on("turbolinks:before-cache", function() {
    var dataTable;

    if ($body.data("litatable")) {
      dataTable = R.LitaTables[$body.data("litatable")];
      dataTable.destroyed = true;
      dataTable.$table.DataTable().destroy();
    }
  });

  var LT = function(properties) {
      this.options = properties.options || {};
      this.namespace = properties.namespace;
      this.searching = properties.searching;
      this.$wrapper = $("#" + this.namespace + "-table-wrapper");
      this.$table = $("#"+this.namespace+"-table");

      this.setup(properties);
      this.create();
  };

  LT.prototype = {
    $s: function(selector) {
      return $("#"+this.namespace+selector);
    },
    create: function() {
      this.events();
       if(this.$table.closest('.table-scroll-wrapper').length == 0) {
        this.$table.addClass('table-scroll-wrapper');
      }
      this.getDataTable();
    },
    setup: function(properties) {
      var that = this;
    // Note: $dateRangeWrapper is used for initializing daterange for relevant datatable container
      var $dateRangeWrapper = this.$s('-table-form-wrapper');
      var dateRange = new window.R.DateRange({
        container: $dateRangeWrapper,
        paramScope: this.namespace,
        rangeSelected: function(label, values) {
          console.log(label, values);
          that.redrawTableWithNewParams();
        },
        ajax: true
      });

      var options = {
        searching: this.searching,
        dataSrc: this.namespace,
        url: this.$table.data('endpoint'),
        paging: properties.paging,
        order: [],
        "dom": 'l<"search-filter-wrapper"f>rtip',
        ajaxData: function (d) {
          d.from = dateRange.from();
          d.to = dateRange.to();
          this.$wrapper.find(".litatable-filters select").each(function () {
            var $el = $(this);
            d[$el.prop('name')] = $el.val();
          });
          this.$wrapper.find(".litatable-filters input:checkbox").each(function () {
            var $el = $(this);
            if ($el.attr('checked')) {
              d[$el.prop('name')] = $el.val();
            }
          });
        }.bind(this)
      };

      options.colvis = $.extend( true, { insertButtonBeforeSelector: "#"+this.namespace+"-table_length" }, properties.colvis );

      if(properties.lengthMenu) {
        options.lengthMenu = properties.lengthMenu;
      } else if(properties.includeAllOptionInLengthMenu !== undefined) {
        options.includeAllOptionInLengthMenu = properties.includeAllOptionInLengthMenu;
      }

      if(properties.serverSideExport === true) {

        this.setupServerSideExport(properties, options);

      } else {

        options.useButtons = true;
        options.insertButtonsAfterSelector = "#"+this.namespace+"-table-export-wrapper";
        options.exportOptions = properties.exportOptions;

      }

      options = $.extend(true, options, this.options);

      options.rowGroup = properties.groupRows;

      this.data = {
        options: options,
        columns: properties.columns,
        dateRange: dateRange,
      };
    },
    redrawTableWithNewParams: function() {
      this.dataTable.ajax.reload();
      window.recognize.patterns.formLoading.resetButton();
    },
    getDataTable: function() {
      if (!this.dataTable) {
        this.dataTable = R.utils.createDataTable(this.data.columns, this.$table, this.data.options);
      }

      return this.dataTable;
    },
    setupServerSideExport: function(properties, options) {
        options.serverSideExport = {
          useButtons: true,
          url: properties.serverSideExportUrl
        };

        var buttonCommon = {
            exportOptions: {
                format: {
                    body: function ( data, row, column, node ) {
                        // Strip $ from salary column to make it numeric
                        return column === 5 ?
                            data.replace( /[$,]/g, '' ) :
                            data;
                    }
                }
            }
        };

        options.serverSideExport.buttons = [
          $.extend( true, {}, buttonCommon, {
              text: 'Export search results',
              action: function ( e, dt, node, config ) {
                this.confirmExportRequest(e,dt,node,config)
              }.bind(this)
          } ),
        ];
        options.serverSideExport.insertButtonsAfterSelector = "#"+this.namespace+"-table-export-wrapper";

    },
    confirmExportRequest: function(e, dt, node, config) {
      Swal.fire({
        title: node.text(),
        html: '<h3>Please choose your file format</h3>',
        showCloseButton: true,
        showCancelButton: true,
        showLoaderOnConfirm: true,
        input: 'select',
        inputValue: 'excel',
        inputOptions: {'csv': 'Csv', 'excel': 'Excel'},
        inputValidator: function(val) {
          if (!val) {
            return 'Please pick a file format'
          }
        },
        preConfirm: function(selectedVal) {
          return new Promise(function(resolve, reject) {
            var $swalContainer = $('.swal2-container');
            var fileParams = {
              file_format: selectedVal // ignored when input is absent
            };
            var datatableParams = this.dataTable.ajax.params();
            var ajaxData = $.extend(true, fileParams, datatableParams);
            this.requestExport(this, ajaxData, resolve, reject);
          }.bind(this)).catch(function (reason) {
            // this prevents the modal from closing when there is an error (eg. validation errors)
            Swal.showValidationMessage(reason);
          });
        }.bind(this)
      });
    },
    requestExport: function(that, data, resolve, reject) {
      var url = this.data.options.serverSideExport.url;

      $.ajax({
        url: url,
        type: 'GET',
        data: data
      }).then(
        function success(response) {
          Swal.fire({
            icon: 'success',
            title: "Export has been queued",
            html: "<ul><li>Your " + data.file_format + " export request has been created. </li><li>You will be emailed when it's complete.</li><li>Once complete, you can click the link in the email or visit the Documents > Download section</li></ul>"
          }).then(resolve);

        },
        function failure(error) {
          var errorMessage = 'Sorry, something went wrong. Please try again later.';
          if (error.status === 422 && error.responseJSON) {
            errorMessage = error.responseJSON.errors.join('<br>');
          }
          reject(errorMessage);
        }
      )
    },

    // groupRowsDrawCallback: function(api, settings) {
    //   console.log();

    //   var rows = api.rows( {page:'current'} ).nodes();
    //   var last=null;

    //   api.rows({page: 'current'}).data().each(function(rowData, i) {
    //     var groupId = settings.groupRows.id(rowData);
    //     if ( last !== groupId ) {
    //         $(rows).eq( i ).before(
    //           settings.groupRows.html(settings, rowData)
    //         );

    //         last = groupId;
    //     }

    //   });

    // }
  };

  LT.prototype.events = function() {
    var that = this,
        searchTimer = 0;

    function search($el) {
      that.getDataTable().search($el.val()).draw();
    }

    this.$wrapper.on("keyup", '.search-pane input', function(e){
      var $el = $(this);
      clearTimeout(searchTimer);

      var code = e.keyCode;
      if ((code >= 9 && code <= 45 && [13, 16, 32].indexOf(code) === -1) ||
          (code >= 91 && code <= 93) ||
          (code >= 112 && code <= 145)) {
        // no op - ignore non-mutating key presses like arrow keys, function keys, ctrl, alt, etc.
        // https://stackoverflow.com/a/44750268
      } else if (code === 13) { // "enter" key
        that.getDataTable().settings()[0].jqXHR.abort();
        search($el);
      } else {
        searchTimer = setTimeout(function() {
          that.getDataTable().settings()[0].jqXHR.abort();
          search($el);
        }, 500);
      }
    });

    this.$wrapper.on('change', '.litatable-filters', function (evt) {
      that.getDataTable().draw();
    });

    this.$table.on('preXhr.dt', function() {
      var $rangeControls = that.$s("-table-form-wrapper");
      var $img = $("<img>");
      $img[0].src = "/assets/icons/ajax-loader-company.gif";
      $rangeControls.find(".selected-heading").html($img);
    });

    this.$table.on('xhr.dt', function() {
      var $rangeControls = that.$s("-table-form-wrapper");
      $rangeControls.find(".selected-heading").html('');
    });


  };

  window.R.LitaTable = LT;
})();
