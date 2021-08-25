/* The MIT License (MIT)

 Copyright (c) 2017 Aaron Cordova

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE. */

function typer(el, speed) {
  var q = []; // The main array to contain all the methods called on typer.

  // Throws an error if el isn't a string selector or HTML element.
  if (checkSelector(el) === 'String') el = document.querySelector(el);

  // Speed check.
  speed = speed > 0 ? speed : 70;

  // List of HTML void elements (http://goo.gl/SWmyS5),
  // used in 'processMsg' & 'processBack'.
  q.voids = ['AREA','BASE','BR','COL','COMMAND','EMBED','HR','IMG','INPUT','KEYGEN','LINK','META','PARAM','SOURCE','TRACK','WBR'];

  // List of class names for cleanup later on.
  q.classNames = ['typer', 'cursor-block', 'cursor-soft', 'cursor-hard', 'no-cursor'];

  // Assign a random # to the parent el's data attribute.
  parentDataNum();

  // Public methods.
  var typerObj = {
    cursor: function(cursorObj) {

      return this;
    },
    line: function(msg, spd, html) {
      var lastArg = arguments[arguments.length - 1];
      var elem = msg !== lastArg && getType(lastArg) === 'String' && lastArg;
      elem = q.voids.includes(elem) && elem;

      q.push(msg ? lineOrContinue('line', msg, spd, html, elem) : {line: 1});

      // Push the first dominoe on the typing iteration,
      // ensuring public methods will only call 'processq()' once.
      if (!q.typing) {
        q.typing = true;
        processq();
      }

      return this;
    },
    continue: function(msg, spd, html) {
      if (!msg) return this; // Ignore empty continues.
      q.push(lineOrContinue('continue', msg, spd, html));
      return this;
    },
    pause: function(num) {
      // Default to 500ms.
      q.push({pause: num || 500});
      return this;
    },
    emit: function(event, el) {
      if (!el) el = document.body;
      if (checkSelector(el) === 'String') el = document.querySelector(el);

      q.push({emit: event, el: el});
      return this;
    },
    listen: function(event, el) {
      if (!el) el = document.body;
      if (checkSelector(el) === 'String') el = document.querySelector(el);

      q.push({listen: event, el: el});
      return this;
    },
    back: function(chars, spd) {
      spd = spd > 0 ? spd : speed;
      q.push({back: chars || 1, speed: spd});
      return this;
    },
    empty: function() {
      q.push({empty: true});
      return this;
    },
    run: function(fxn) {
      q.push({run: fxn});
      return this;
    },
    end: function(fxn, e) {
      q.push({end: true});

      q.cb = function() {
        q.style && q.style.remove();
        classNameCleanup(); // Finalize the div class names before ending.
        q.newDiv.classList.add('white-space');
        q.newDiv = '';

        if (fxn && fxn instanceof Function) fxn(el);
        if ((fxn && getType(fxn) === 'Boolean') || e) {
          if (e instanceof Function) e(el);
          document.body.dispatchEvent(new Event('typerFinished'));
        }
      };

      // A convenient object to warn the user if they
      // try to call any methods after '.end'.
      var catchAll = {
        cursor: message,
        line: message,
        continue: message,
        pause: message,
        emit: message,
        listen: message,
        back: message,
        empty: message,
        run: message,
        end: message
      };

      // Message used by the 'catchAll' object.
      function message() {
        console.warn('WARNING: you tried to call a method after ".end" has already been called.');
        return catchAll;
      }

      return catchAll;
    }
  };

  // Private functions.
  function getType(thing) {
    return ({}).toString.call(thing).slice(8, -1);
  }
  function checkSelector(thing) {
    var type = getType(thing);
    if (type.slice(0, 4) !== 'HTML' && type !== 'String') {
      throw 'You need to provide a string selector, such as ".some-class", or an html element.'
    }
    return type;
  }
  function classNameCleanup() {
    ['typer', 'cursor-block', 'cursor-soft', 'cursor-hard', 'no-cursor'].forEach(function(name) {
      q.newDiv.classList.remove(name);
  });
}
function parentDataNum() {
  // Random # function with min & max values.
  // function randomNum(min, max) {
  //   return Math.floor(Math.random() * (max - min + 1) + min);
  // }
  q.dataNum = Math.floor(Math.random() * 999999999 + 1);
  el.setAttribute('data-typer', q.dataNum);
}
function addStyle(selector, rules) { // https://goo.gl/b4Ckz9
  q.style = document.createElement('style'); // Create the style element.
  q.style.appendChild(document.createTextNode('')); // Webkit hack - https://goo.gl/b4Ckz9
  document.head.appendChild(q.style); // Append the style element to the head.
  var sheet = document.styleSheets[document.styleSheets.length - 1];

  if ('insertRule' in sheet) {
    sheet.insertRule('${selector}{${rules}}', 0);
  } else {
    sheet.addRule(selector, rules);
  }
}
function lineOrContinue(choice, msg, spd, html, elem) {
  var obj = {
    html: (spd === false || html === false) ? false : true,
    elem: elem
  };

  if (getType(spd) === 'Number') obj.speed = spd > 0 ? spd : speed;
  if (getType(html) === 'Number') obj.speed = html;
  if (getType(msg) === 'Object') {
    var key = Object.keys(msg)[0]; // Prevents a hard dependency on 'el' as the property name.
    var val = checkSelector(msg[key]) === 'String' ? document.querySelector(msg[key]) : msg[key];
    msg = val[obj.html ? 'innerHTML': 'textContent'].trim();
  }

  obj.speed = obj.speed || speed;
  obj[choice] = msg;

  return obj;
}
function processq() { // Begin our main iterator.
  if (!(q.item >= 0)) q.item = 0;
  if (q.item === q.length) return document.body.removeEventListener('killTyper', q.kill);
  if (!q.ks) {
    q.ks = true;
    document.body.addEventListener('killTyper', q.kill);
  }


  // Main iterator.
  q.type = setInterval(function() {
    var item = q[q.item];

    // Various processing functions.
    item.line ? processLine(item) :
      item.continue ? processContinue(item) :
        item.pause ? processPause(item) :
          item.emit ? processEmit(item) :
            item.listen ? processListen(item) :
              item.back ? processBack(item) :
                item.empty ? processEmpty() :
                  item.run ? processRun(item) :
                  item.end && processEnd(item);
  }, 0);
}
function processMsg(item) { // Used by 'processLine' & 'processContinue'.
  var msg = item.line || item.continue;
  var div = document.createElement('div');

  if (Array.isArray(msg)) return typeArrays(item.html);

  div.innerHTML = msg;
  item.html ? html() : plain();

  function typeArrays(html) {
    var counter = 0;

    q.iterator = setInterval(function() {
        var content = msg[counter++];

    div.textContent = content;
    q.newDiv.innerHTML += html ? content : div.innerHTML;

    if (counter === msg.length) moveOn();
  }, item.speed);
}

function html() {
  var list = createTypingArray(div.childNodes, q.newDiv);
  var objCounter = 0;
  var textCounter = 0;
  var obj = list[objCounter++];

  q.iterator = setInterval(function() {
      // Finished processing everything.
      if (!obj) return moveOn();

  // Text node.
  if (obj.content) {
    obj.parent.innerHTML += obj.content[textCounter++];

    // Finished typing.
    if (textCounter === obj.content.length) {
      textCounter = 0;
      obj = list[objCounter++]
    }

    // Void & non-void element nodes.
  } else {
    obj.parent.appendChild(obj.voidNode || obj.newNode);
    obj = list[objCounter++];
  }
}, item.speed);
}

function plain() {
  var counter = 0;

  q.iterator = setInterval(function() {
      // End of message processing logic.
      if (counter === msg.length) {
    clearInterval(q.iterator);
    q.item++; // Increment our main item counter.
    return processq(); // Restart the main iterator.
  }

  var piece = msg[counter];

  // Avoid HTML parsing on supplied arrays.
  if (getType(msg) !== 'String') {
    div.textContent = piece;
    piece = div.innerHTML;
  }

  q.newDiv.innerHTML += piece;
  counter++;
}, item.speed);
}

function createTypingArray(childNodes, parent) {
  var arr = [];
  childNodes = Array.from(childNodes);

  for (var i = 0; i < childNodes.length; i++) {
    var node = childNodes[i];
    var name = node.nodeName;

    // Text nodes.
    if (name === '#text') {
      // Only text nodes will get the content property.
      arr.push({
        parent: parent,
        content: node.textContent
      });

      // Non-void elements.
    } else if (node.childNodes.length) {
      // 1. Clone to an empty node.
      var newNode = document.createElement(name);

      // 2. Copy the attributes.
      copyAttributes(node, newNode);

      arr.push({
        parent: parent,
        newNode: newNode,
      });

      arr = arr.concat(createTypingArray(node.childNodes, newNode));

      // Void elements.
    } else if (q.voids.includes(name)) {
      arr.push({
        parent: parent,
        voidNode: node
      });
    }
  }

  return arr;
}

// Stop the typing iteration & move on to our main iteration.
function moveOn() {
  clearInterval(q.iterator);
  q.item++; // Increment our main item counter.
  return processq(); // Restart the main iterator.
}

function copyAttributes(source, target) {
  Array.from(source.attributes).forEach(function(attr) {
    target.setAttribute(attr.name, attr.value);
});
}
}
function processLine(item) {
  // Stop the main iterator.
  clearInterval(q.type);

  // Process the previous line if there was one.
  if (q.newDiv) {
    classNameCleanup();
    q.newDiv.classList.add('white-space');
    if (!q.newDiv.innerHTML) q.newDiv.innerHTML = ' '; // Retains the height of a single line.
  }

  // Create new div (or specified element).
  var div = document.createElement(item.elem || 'div');
  div.setAttribute('data-typer-child', q.dataNum);
  div.className = q.cursor;
  div.classList.add('typer');
  div.classList.add('white-space');

  el.appendChild(div);
  q.newDiv = div;

  // If our line has no contents...
  if (item.line === 1) {
    q.item++;
    return processq();
  }

  // Message iterator.
  processMsg(item);
}
function processContinue(item) {
  clearInterval(q.type); // Stop the main iterator.
  processMsg(item); // Message iterator.
}
function processPause(item) {
  clearInterval(q.type); // Stop the main iterator.

  q.pause = setTimeout(function() {
      q.item++; // Increment our main item counter.
  processq(); // Restart the main iterator.
}, item.pause);
}
function processEmit(item) {
  clearInterval(q.type); // Stop the main iterator.
  document.querySelector(item.el).dispatchEvent(new Event(item.emit));

  q.item++;
  processq();
}
function processListen(item) {
  clearInterval(q.type); // Stop the main iterator.

  var el = document.querySelector(item.el);

  // One-time event listener.
  el.addEventListener(item.listen, function handler(e) {
    el.removeEventListener(e.type, handler);
    if (q.killed) return; // Prevent error if kill switch is engaged.
    q.item++;
    processq();
  });
}
function processBack(item) {
  // Stop the main iterator.
  clearInterval(q.type);

  // Check for being called on an empty line.
  if (!q.newDiv || !q.newDiv.textContent) {
    q.item++;
    return processq();
  }

  // Empty the line all at once.
  if (item.back === 'empty') {
    q.newDiv.innerHTML = '';
    q.item++;
    return processq();
  }

  var totalVoids = countVoids(q.newDiv);

  // Prevent larger 'back' quantities from needlessly interrupting the flow.
  if (item.back > q.newDiv.textContent.length + totalVoids) item.back = 'all';

  // A simple way to erase the whole line without knowing the contents:
  // set the # of 'backspaces' to the content's length + any void elements to be removed.
  if (item.back === 'all') item.back = q.newDiv.textContent.length + totalVoids;

  // Negative #'s are an easy way to say "erase all BUT X-amount of characters."
  if (item.back < 0) {
    var totalLength = q.newDiv.textContent.length + totalVoids;
    item.back = totalLength - (item.back * -1);
  }

  var counter = 0;
  var contents = flattenContents(q.newDiv).reverse();

  q.goBack = setInterval(function() {
    var node = contents[0];
    var isVoid = q.voids.includes(node.nodeName);

    if (isVoid) {
      node.remove();
      contents.shift();
    } else {
      node.textContent = node.textContent.slice(0, -1);
      if (!node.length) contents.shift();
    }

    counter++;

    // Exit.
    if (counter === item.back) {
      clearInterval(q.goBack);
      removeEmpties(q.newDiv);
      q.item++;
      processq();
    }
  }, item.speed);

  function flattenContents(parent) {
    var arr = [];
    var childNodes = Array.from(parent.childNodes);

    if (!childNodes.length) return arr;

    childNodes.forEach(function(child) {
      if (child.childNodes.length) {
      arr = arr.concat(flattenContents(child));
    } else {
      arr.push(child);
    }
  });

  return arr;
}

function removeEmpties(el) {
  Array.from(el.childNodes).forEach(function(child, index) {
    if (q.voids.includes(child.nodeName)) return; // Do not remove void tags.
  if (child.childNodes.length) removeEmpties(child);
  if (child.nodeName !== '#text' && !child.innerHTML.length) child.remove();
  if (child.nodeName === '#text' && !child.length) delete el.childNodes[index];
});
}

function countVoids(el) {
  var num = 0;

  Array.from(el.childNodes).forEach(function(child) {
    if (q.voids.includes(child.nodeName)) num++;
  if (child.childNodes.length) num += countVoids(child);
});

return num;
}
}
function processEmpty() {
  q.newDiv = '';
  el.innerHTML = '';
  processLine({line: 1}); // This will stop the main iterator & run 'processq'.
}
function processRun(item) {
  clearInterval(q.type); // Stop the main iterator.

  item.run(el);
  q.item++;
  processq();
}
function processEnd() {
  clearInterval(q.type); // Final stop to our main iterator.
  q.cb(); // Run the callback provided.
}

// The kill switch.
q.kill = function(e) {
  document.body.removeEventListener(e.type, q.kill);
  q.killed = true; // For processListen.

  // Stop all iterations & pauses.
  clearInterval(q.iterator); // From processMsg.
  clearInterval(q.goBack); // From processBack.
  clearTimeout(q.pause) // From processPause.

  if (q.item === q.length) return console.log('This typer has compvared. Listeners removed.');

  // If typer is in a listener state...
  var ear = q[q.item];
  if (ear && ear.listen) {
    var el = document.querySelector(ear.el);
    el.dispatchEvent(new Event(ear.listen));
  }
};

// Return 'typerObj' to be able to run the various methods.
return typerObj;
}