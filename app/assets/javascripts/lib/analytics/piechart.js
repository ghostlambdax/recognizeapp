window.R = window.R || {};
window.R.analytics = window.R.analytics || {};
window.R.analytics.piechart = function(options) {
  var timer = 0, maxTimes = 50;

  if (!options || !options.data) {
    return;
  }

  options.title = options.title || '';
  options.container = options.container || 'piechart';


  function initPieChartWhenHighchartsIsReady() {
    if (maxTimes === 0) {
      console.warn("Highcharts never loaded");
      return clearTimeout(timer);
    }

    if (!window.Highcharts && !$("#highcharts-script").length) {
      var script = document.createElement("script");
      script.src = "https://code.highcharts.com/highcharts.js";
      script.id = 'highcharts-script';
      document.head.appendChild(script);

      script.addEventListener("load", function() {
        script = document.createElement("script");
        script.src = "https://code.highcharts.com/modules/no-data-to-display.js";
        document.head.appendChild(script);
      });
    }

    maxTimes--;

    if (!window.Highcharts) {
      timer = setTimeout(initPieChartWhenHighchartsIsReady, 300);
    } else {
      clearTimeout(timer);
      return Highcharts.chart(options.container, {
        chart: {
          plotBackgroundColor: null,
          plotBorderWidth: null,
          plotShadow: false,
          type: 'pie'
        },
        title: {
          text: options.title
        },
        tooltip: {
          pointFormat: '{point.y:.0f} ({point.percentage:.1f}%)'
        },
        plotOptions: {
          pie: {
            allowPointSelect: true,
            cursor: 'pointer',
            dataLabels: {
              enabled: false
            },
            showInLegend: true
          }
        },
        series: options.data,
        lang: options.lang
      });
    }
  }

  initPieChartWhenHighchartsIsReady();
};