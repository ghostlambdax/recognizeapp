
window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["award_generator-service_anniversary"] = (function() {
  var AwardGenerator = function() {
    this.addEvents();

    this.stage = new Konva.Stage({
      container: 'award-viewpoint',
      width: 3300,
      height: 2550
    });

    this.layer = new Konva.Layer();
    this.stage.add(this.layer);

    this.fontfamily = this.getFontFamily(); 'bitter, serif';

    this.content = this.getContent();

    this.setBackground("/assets/pages/award-generator/years-of-service.png");
  };

  AwardGenerator.prototype.getFontFamily = function() {
    var $el = $('#fontFamily');
    var that = this;

    $document.on('keyup', '#fontFamily', function(event) {
      for (var el in that.content) {
        that.content[el].fontFamily(event.target.value || 'bitter, serif');
      }

      that.layer.draw();
      that.fontFamily = event.target.value;
    });

    return $el.prop('value');
  };

  AwardGenerator.prototype.getContent = function() {
    var content = {};
    var $controls = $(".text-options .control");
    var that = this;

    $controls.each(function() {
      var $this = $(this);

      var obj = {
        text: $this.find("input[type='text']").prop('value'),
        x: $this.data('x'),
        y: $this.data('y'),
        draggable: $this.data('draggable'),
        fontFamily: that.fontfamily,
        fill: $this.data('fill'),
        width: $this.data('width'),
        align: ($this.data('align') || 'left'),
        fontSize: $this.data('fontsize')
      };

      content[$this.prop("id")] = that.addText(obj);

      that.setEvent($this);
    });

    return content;
  };

  AwardGenerator.prototype.setEvent = function($controlGroup) {
    var that = this;
    $controlGroup.find("input[type='color']").change(function(event) {
      that.content[$controlGroup.prop('id')].fill( event.target.value );
      that.layer.draw();
    });

    $controlGroup.find("input[type='text']").keyup(function(event) {
      that.content[$controlGroup.prop('id')].setText( event.target.value );
      that.layer.draw();
    });
  };

  AwardGenerator.prototype.addEvents = function() {
    $document.on(R.touchEvent, ".certificateThumbnails img", function() {
      var path = $(this).attr("src");
      this.setBackground(path);
    }.bind(this));

    $document.on('change', '#langauge-select', function() {
      window.location = R.utils.addParamsToUrlString('./service-anniversary', {'locale': this.value});
    });

    $document.on(R.touchEvent, '#export-pdf', function() {
      htmlToImage();
    });
  };

  function htmlToImage() {
    var pdf;
    var canvas = $("#award-viewpoint canvas")[0];
    var dataURI = canvas.toDataURL();
    console.log(dataURI);


    var dd = {
      pageSize: {
        width: 3300,
        height: 2550
      },

      // by default we use portrait, you can change it to landscape if you wish
      pageOrientation: 'landscape',

      // [left, top, right, bottom] or [horizontal, vertical] or just a number for equal margins
      pageMargins: [ 0,0,0,0 ],
      content: [
        {
          height: 2550,
          width: 3300,
          image: dataURI,
          fit: [3300, 2550]
        }
      ]
    };

    pdf = pdfMake.createPdf(dd);
    pdf.download();
  }

  AwardGenerator.prototype.setBackground = function(src) {
    var width = window.innerWidth;
    var height = window.innerHeight;
    var that = this;

    Konva.Image.fromURL(src, function(image) {
      // image is Konva.Image instance
      image.width(3300);
      image.height(2550);
      that.layer.add(image);
      image.moveToBottom();
      that.layer.draw();
    });
  };

  AwardGenerator.prototype.addText = function(opts) {
    return this.konvaText(opts);
  };

  AwardGenerator.prototype.konvaText = function(opts) {
    var that = this;

    var textNode = new Konva.Text(opts);

    this.layer.add(textNode);
    this.layer.draw();

    textNode.on('dblclick dbltap', () => {
      // create textarea over canvas with absolute position
      // first we need to find position for textarea
      // how to find it?

      // at first lets find position of text node relative to the stage:
      var textPosition = textNode.getAbsolutePosition();

      // then lets find position of stage container on the page:
      var stageBox = this.stage.container().getBoundingClientRect();

      // so position of textarea will be the sum of positions above:
      var areaPosition = {
        x: stageBox.left + textPosition.x,
        y: stageBox.top + textPosition.y,
      };

      // create textarea and style it
      var textarea = document.createElement('textarea');
      document.body.appendChild(textarea);

      textarea.value = textNode.text();
      textarea.style.position = 'absolute';
      textarea.style.top = areaPosition.y + 'px';
      textarea.style.left = areaPosition.x + 'px';
      textarea.style.width = textNode.width();

      textarea.focus();

      textarea.addEventListener('keydown', function (e) {
        // hide on enter
        if (e.keyCode === 13) {
          textNode.text(textarea.value);
          that.layer.draw();
          document.body.removeChild(textarea);
        }
      });
    });

    return textNode;
  };

  return AwardGenerator;

})();







