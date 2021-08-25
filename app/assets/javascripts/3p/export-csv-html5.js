// https://jsfiddle.net/terryyounghk/kpegu/

window.R = window.R || {};
R.exportTableToCSV = function($table, filename) {
  var $rows = $table.find('tr:has(th), tr:has(td)');

  if (Modernizr.ie) {
    return Swal.fire({
      icon: 'info',
      text: 'This feature is currently supported in modern browsers only such as Chrome, Firefox, Safari and Microsoft Edge. Please contact us at support@recognizeapp.com if you need further assistance.'
    });
  }

  // Remove images
  $rows.find("img").hide();

  // Temporary delimiter characters unlikely to be typed by keyboard
  // This is to avoid accidentally splitting the actual contents
  var tmpColDelim = String.fromCharCode(11), // vertical tab character
  tmpRowDelim = String.fromCharCode(0), // null character

  // actual delimiter characters for CSV format
  colDelim = '","',
  rowDelim = '"\r\n"',

  // Grab text from table into CSV formatted string
  csv = '"' + $rows.map(function (i, row) {
      var $row = $(row),
        $cols = $row.find('th, td').not('.export-ignore');

      return $cols.map(function (j, col) {
        var $col = $(col),
          text = $col.text();

        text = text.replace(/^\s+|\s+$/g, '');

        return text.replace(/"/g, '""'); // escape double quotes

      }).get().join(tmpColDelim);

    }).get().join(tmpRowDelim)
      .split(tmpRowDelim).join(rowDelim)
      .split(tmpColDelim).join(colDelim) + '"',

  // Data URI
  csvData = 'data:application/csv;charset=utf-8,' + encodeURIComponent(csv);

  $(this)
    .attr({
      'download': filename,
      'href': csvData,
      'target': '_blank'
    }
  );

  $rows.find("img").show();
};