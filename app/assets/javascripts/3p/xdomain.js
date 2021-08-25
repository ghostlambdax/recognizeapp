/*! JSON v3.3.2 | http://bestiejs.github.io/json3 | Copyright 2012-2014, Kit Cambridge | http://kit.mit-license.org */
(function(){function N(p,r){function q(a){if(q[a]!==w)return q[a];var c;if("bug-string-char-index"==a)c="a"!="a"[0];else if("json"==a)c=q("json-stringify")&&q("json-parse");else{var e;if("json-stringify"==a){c=r.stringify;var b="function"==typeof c&&s;if(b){(e=function(){return 1}).toJSON=e;try{b="0"===c(0)&&"0"===c(new t)&&'""'==c(new A)&&c(u)===w&&c(w)===w&&c()===w&&"1"===c(e)&&"[1]"==c([e])&&"[null]"==c([w])&&"null"==c(null)&&"[null,null,null]"==c([w,u,null])&&'{"a":[1,true,false,null,"\\u0000\\b\\n\\f\\r\\t"]}'==
  c({a:[e,!0,!1,null,"\x00\b\n\f\r\t"]})&&"1"===c(null,e)&&"[\n 1,\n 2\n]"==c([1,2],null,1)&&'"-271821-04-20T00:00:00.000Z"'==c(new C(-864E13))&&'"+275760-09-13T00:00:00.000Z"'==c(new C(864E13))&&'"-000001-01-01T00:00:00.000Z"'==c(new C(-621987552E5))&&'"1969-12-31T23:59:59.999Z"'==c(new C(-1))}catch(f){b=!1}}c=b}if("json-parse"==a){c=r.parse;if("function"==typeof c)try{if(0===c("0")&&!c(!1)){e=c('{"a":[1,true,false,null,"\\u0000\\b\\n\\f\\r\\t"]}');var n=5==e.a.length&&1===e.a[0];if(n){try{n=!c('"\t"')}catch(d){}if(n)try{n=
  1!==c("01")}catch(g){}if(n)try{n=1!==c("1.")}catch(m){}}}}catch(X){n=!1}c=n}}return q[a]=!!c}p||(p=k.Object());r||(r=k.Object());var t=p.Number||k.Number,A=p.String||k.String,H=p.Object||k.Object,C=p.Date||k.Date,G=p.SyntaxError||k.SyntaxError,K=p.TypeError||k.TypeError,L=p.Math||k.Math,I=p.JSON||k.JSON;"object"==typeof I&&I&&(r.stringify=I.stringify,r.parse=I.parse);var H=H.prototype,u=H.toString,v,B,w,s=new C(-0xc782b5b800cec);try{s=-109252==s.getUTCFullYear()&&0===s.getUTCMonth()&&1===s.getUTCDate()&&
  10==s.getUTCHours()&&37==s.getUTCMinutes()&&6==s.getUTCSeconds()&&708==s.getUTCMilliseconds()}catch(Q){}if(!q("json")){var D=q("bug-string-char-index");if(!s)var x=L.floor,M=[0,31,59,90,120,151,181,212,243,273,304,334],E=function(a,c){return M[c]+365*(a-1970)+x((a-1969+(c=+(1<c)))/4)-x((a-1901+c)/100)+x((a-1601+c)/400)};(v=H.hasOwnProperty)||(v=function(a){var c={},e;(c.__proto__=null,c.__proto__={toString:1},c).toString!=u?v=function(a){var c=this.__proto__;a=a in(this.__proto__=null,this);this.__proto__=
  c;return a}:(e=c.constructor,v=function(a){var c=(this.constructor||e).prototype;return a in this&&!(a in c&&this[a]===c[a])});c=null;return v.call(this,a)});B=function(a,c){var e=0,b,f,n;(b=function(){this.valueOf=0}).prototype.valueOf=0;f=new b;for(n in f)v.call(f,n)&&e++;b=f=null;e?B=2==e?function(a,c){var e={},b="[object Function]"==u.call(a),f;for(f in a)b&&"prototype"==f||v.call(e,f)||!(e[f]=1)||!v.call(a,f)||c(f)}:function(a,c){var e="[object Function]"==u.call(a),b,f;for(b in a)e&&"prototype"==
b||!v.call(a,b)||(f="constructor"===b)||c(b);(f||v.call(a,b="constructor"))&&c(b)}:(f="valueOf toString toLocaleString propertyIsEnumerable isPrototypeOf hasOwnProperty constructor".split(" "),B=function(a,c){var e="[object Function]"==u.call(a),b,h=!e&&"function"!=typeof a.constructor&&F[typeof a.hasOwnProperty]&&a.hasOwnProperty||v;for(b in a)e&&"prototype"==b||!h.call(a,b)||c(b);for(e=f.length;b=f[--e];h.call(a,b)&&c(b));});return B(a,c)};if(!q("json-stringify")){var U={92:"\\\\",34:'\\"',8:"\\b",
  12:"\\f",10:"\\n",13:"\\r",9:"\\t"},y=function(a,c){return("000000"+(c||0)).slice(-a)},R=function(a){for(var c='"',b=0,h=a.length,f=!D||10<h,n=f&&(D?a.split(""):a);b<h;b++){var d=a.charCodeAt(b);switch(d){case 8:case 9:case 10:case 12:case 13:case 34:case 92:c+=U[d];break;default:if(32>d){c+="\\u00"+y(2,d.toString(16));break}c+=f?n[b]:a.charAt(b)}}return c+'"'},O=function(a,c,b,h,f,n,d){var g,m,k,l,p,r,s,t,q;try{g=c[a]}catch(z){}if("object"==typeof g&&g)if(m=u.call(g),"[object Date]"!=m||v.call(g,
    "toJSON"))"function"==typeof g.toJSON&&("[object Number]"!=m&&"[object String]"!=m&&"[object Array]"!=m||v.call(g,"toJSON"))&&(g=g.toJSON(a));else if(g>-1/0&&g<1/0){if(E){l=x(g/864E5);for(m=x(l/365.2425)+1970-1;E(m+1,0)<=l;m++);for(k=x((l-E(m,0))/30.42);E(m,k+1)<=l;k++);l=1+l-E(m,k);p=(g%864E5+864E5)%864E5;r=x(p/36E5)%24;s=x(p/6E4)%60;t=x(p/1E3)%60;p%=1E3}else m=g.getUTCFullYear(),k=g.getUTCMonth(),l=g.getUTCDate(),r=g.getUTCHours(),s=g.getUTCMinutes(),t=g.getUTCSeconds(),p=g.getUTCMilliseconds();
  g=(0>=m||1E4<=m?(0>m?"-":"+")+y(6,0>m?-m:m):y(4,m))+"-"+y(2,k+1)+"-"+y(2,l)+"T"+y(2,r)+":"+y(2,s)+":"+y(2,t)+"."+y(3,p)+"Z"}else g=null;b&&(g=b.call(c,a,g));if(null===g)return"null";m=u.call(g);if("[object Boolean]"==m)return""+g;if("[object Number]"==m)return g>-1/0&&g<1/0?""+g:"null";if("[object String]"==m)return R(""+g);if("object"==typeof g){for(a=d.length;a--;)if(d[a]===g)throw K();d.push(g);q=[];c=n;n+=f;if("[object Array]"==m){k=0;for(a=g.length;k<a;k++)m=O(k,g,b,h,f,n,d),q.push(m===w?"null":
  m);a=q.length?f?"[\n"+n+q.join(",\n"+n)+"\n"+c+"]":"["+q.join(",")+"]":"[]"}else B(h||g,function(a){var c=O(a,g,b,h,f,n,d);c!==w&&q.push(R(a)+":"+(f?" ":"")+c)}),a=q.length?f?"{\n"+n+q.join(",\n"+n)+"\n"+c+"}":"{"+q.join(",")+"}":"{}";d.pop();return a}};r.stringify=function(a,c,b){var h,f,n,d;if(F[typeof c]&&c)if("[object Function]"==(d=u.call(c)))f=c;else if("[object Array]"==d){n={};for(var g=0,k=c.length,l;g<k;l=c[g++],(d=u.call(l),"[object String]"==d||"[object Number]"==d)&&(n[l]=1));}if(b)if("[object Number]"==
  (d=u.call(b))){if(0<(b-=b%1))for(h="",10<b&&(b=10);h.length<b;h+=" ");}else"[object String]"==d&&(h=10>=b.length?b:b.slice(0,10));return O("",(l={},l[""]=a,l),f,n,h,"",[])}}if(!q("json-parse")){var V=A.fromCharCode,W={92:"\\",34:'"',47:"/",98:"\b",116:"\t",110:"\n",102:"\f",114:"\r"},b,J,l=function(){b=J=null;throw G();},z=function(){for(var a=J,c=a.length,e,h,f,k,d;b<c;)switch(d=a.charCodeAt(b),d){case 9:case 10:case 13:case 32:b++;break;case 123:case 125:case 91:case 93:case 58:case 44:return e=
  D?a.charAt(b):a[b],b++,e;case 34:e="@";for(b++;b<c;)if(d=a.charCodeAt(b),32>d)l();else if(92==d)switch(d=a.charCodeAt(++b),d){case 92:case 34:case 47:case 98:case 116:case 110:case 102:case 114:e+=W[d];b++;break;case 117:h=++b;for(f=b+4;b<f;b++)d=a.charCodeAt(b),48<=d&&57>=d||97<=d&&102>=d||65<=d&&70>=d||l();e+=V("0x"+a.slice(h,b));break;default:l()}else{if(34==d)break;d=a.charCodeAt(b);for(h=b;32<=d&&92!=d&&34!=d;)d=a.charCodeAt(++b);e+=a.slice(h,b)}if(34==a.charCodeAt(b))return b++,e;l();default:h=
  b;45==d&&(k=!0,d=a.charCodeAt(++b));if(48<=d&&57>=d){for(48==d&&(d=a.charCodeAt(b+1),48<=d&&57>=d)&&l();b<c&&(d=a.charCodeAt(b),48<=d&&57>=d);b++);if(46==a.charCodeAt(b)){for(f=++b;f<c&&(d=a.charCodeAt(f),48<=d&&57>=d);f++);f==b&&l();b=f}d=a.charCodeAt(b);if(101==d||69==d){d=a.charCodeAt(++b);43!=d&&45!=d||b++;for(f=b;f<c&&(d=a.charCodeAt(f),48<=d&&57>=d);f++);f==b&&l();b=f}return+a.slice(h,b)}k&&l();if("true"==a.slice(b,b+4))return b+=4,!0;if("false"==a.slice(b,b+5))return b+=5,!1;if("null"==a.slice(b,
    b+4))return b+=4,null;l()}return"$"},P=function(a){var c,b;"$"==a&&l();if("string"==typeof a){if("@"==(D?a.charAt(0):a[0]))return a.slice(1);if("["==a){for(c=[];;b||(b=!0)){a=z();if("]"==a)break;b&&(","==a?(a=z(),"]"==a&&l()):l());","==a&&l();c.push(P(a))}return c}if("{"==a){for(c={};;b||(b=!0)){a=z();if("}"==a)break;b&&(","==a?(a=z(),"}"==a&&l()):l());","!=a&&"string"==typeof a&&"@"==(D?a.charAt(0):a[0])&&":"==z()||l();c[a.slice(1)]=P(z())}return c}l()}return a},T=function(a,b,e){e=S(a,b,e);e===
w?delete a[b]:a[b]=e},S=function(a,b,e){var h=a[b],f;if("object"==typeof h&&h)if("[object Array]"==u.call(h))for(f=h.length;f--;)T(h,f,e);else B(h,function(a){T(h,a,e)});return e.call(a,b,h)};r.parse=function(a,c){var e,h;b=0;J=""+a;e=P(z());"$"!=z()&&l();b=J=null;return c&&"[object Function]"==u.call(c)?S((h={},h[""]=e,h),"",c):e}}}r.runInContext=N;return r}var K=typeof define==="function"&&define.amd,F={"function":!0,object:!0},G=F[typeof exports]&&exports&&!exports.nodeType&&exports,k=F[typeof window]&&
  window||this,t=G&&F[typeof module]&&module&&!module.nodeType&&"object"==typeof global&&global;!t||t.global!==t&&t.window!==t&&t.self!==t||(k=t);if(G&&!K)N(k,G);else{var L=k.JSON,Q=k.JSON3,M=!1,A=N(k,k.JSON3={noConflict:function(){M||(M=!0,k.JSON=L,k.JSON3=Q,L=Q=null);return A}});k.JSON={parse:A.parse,stringify:A.stringify}}K&&define(function(){return A})}).call(this);


function getInternetExplorerVersion() {
  var rv = -1;
  if (navigator.appName == 'Microsoft Internet Explorer')
  {
    var ua = navigator.userAgent;
    var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
    if (re.exec(ua) != null)
      rv = parseFloat( RegExp.$1 );
  }
  else if (navigator.appName == 'Netscape')
  {
    var ua = navigator.userAgent;
    var re  = new RegExp("Trident/.*rv:([0-9]{1,}[\.0-9]{0,})");
    if (re.exec(ua) != null)
      rv = parseFloat( RegExp.$1 );
  }
  return rv;
}

// XDomain - v0.7.5 - https://github.com/jpillora/xdomain
// Jaime Pillora <dev@jpillora.com> - MIT Copyright 2016
(function(window,undefined) {
  var ieVersion = getInternetExplorerVersion();

  if ( ieVersion && ieVersion > 10 ) {
    return;
  }

// XHook - v1.3.5 - https://github.com/jpillora/xhook
// Jaime Pillora <dev@jpillora.com> - MIT Copyright 2016
(function(window,undefined) {
var AFTER, BEFORE, COMMON_EVENTS, EventEmitter, FIRE, FormData, NativeFormData, NativeXMLHttp, OFF, ON, READY_STATE, UPLOAD_EVENTS, XHookFormData, XHookHttpRequest, XMLHTTP, convertHeaders, depricatedProp, document, fakeEvent, mergeObjects, msie, proxyEvents, slice, xhook, _base,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

document = window.document;

BEFORE = 'before';

AFTER = 'after';

READY_STATE = 'readyState';

ON = 'addEventListener';

OFF = 'removeEventListener';

FIRE = 'dispatchEvent';

XMLHTTP = 'XMLHttpRequest';

FormData = 'FormData';

UPLOAD_EVENTS = ['load', 'loadend', 'loadstart'];

COMMON_EVENTS = ['progress', 'abort', 'error', 'timeout'];

msie = parseInt((/msie (\d+)/.exec(navigator.userAgent.toLowerCase()) || [])[1]);

if (isNaN(msie)) {
  msie = parseInt((/trident\/.*; rv:(\d+)/.exec(navigator.userAgent.toLowerCase()) || [])[1]);
}

(_base = Array.prototype).indexOf || (_base.indexOf = function(item) {
  var i, x, _i, _len;
  for (i = _i = 0, _len = this.length; _i < _len; i = ++_i) {
    x = this[i];
    if (x === item) {
      return i;
    }
  }
  return -1;
});

slice = function(o, n) {
  return Array.prototype.slice.call(o, n);
};

depricatedProp = function(p) {
  return p === "returnValue" || p === "totalSize" || p === "position";
};

mergeObjects = function(src, dst) {
  var k, v;
  for (k in src) {
    v = src[k];
    if (depricatedProp(k)) {
      continue;
    }
    try {
      dst[k] = src[k];
    } catch (_error) {}
  }
  return dst;
};

proxyEvents = function(events, src, dst) {
  var event, p, _i, _len;
  p = function(event) {
    return function(e) {
      var clone, k, val;
      clone = {};
      for (k in e) {
        if (depricatedProp(k)) {
          continue;
        }
        val = e[k];
        clone[k] = val === src ? dst : val;
      }
      return dst[FIRE](event, clone);
    };
  };
  for (_i = 0, _len = events.length; _i < _len; _i++) {
    event = events[_i];
    if (dst._has(event)) {
      src["on" + event] = p(event);
    }
  }
};

fakeEvent = function(type) {
  var msieEventObject;
  if (document.createEventObject != null) {
    msieEventObject = document.createEventObject();
    msieEventObject.type = type;
    return msieEventObject;
  } else {
    try {
      return new Event(type);
    } catch (_error) {
      return {
        type: type
      };
    }
  }
};

EventEmitter = function(nodeStyle) {
  var emitter, events, listeners;
  events = {};
  listeners = function(event) {
    return events[event] || [];
  };
  emitter = {};
  emitter[ON] = function(event, callback, i) {
    events[event] = listeners(event);
    if (events[event].indexOf(callback) >= 0) {
      return;
    }
    i = i === undefined ? events[event].length : i;
    events[event].splice(i, 0, callback);
  };
  emitter[OFF] = function(event, callback) {
    var i;
    if (event === undefined) {
      events = {};
      return;
    }
    if (callback === undefined) {
      events[event] = [];
    }
    i = listeners(event).indexOf(callback);
    if (i === -1) {
      return;
    }
    listeners(event).splice(i, 1);
  };
  emitter[FIRE] = function() {
    var args, event, i, legacylistener, listener, _i, _len, _ref;
    args = slice(arguments);
    event = args.shift();
    if (!nodeStyle) {
      args[0] = mergeObjects(args[0], fakeEvent(event));
    }
    legacylistener = emitter["on" + event];
    if (legacylistener) {
      legacylistener.apply(emitter, args);
    }
    _ref = listeners(event).concat(listeners("*"));
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      listener = _ref[i];
      listener.apply(emitter, args);
    }
  };
  emitter._has = function(event) {
    return !!(events[event] || emitter["on" + event]);
  };
  if (nodeStyle) {
    emitter.listeners = function(event) {
      return slice(listeners(event));
    };
    emitter.on = emitter[ON];
    emitter.off = emitter[OFF];
    emitter.fire = emitter[FIRE];
    emitter.once = function(e, fn) {
      var fire;
      fire = function() {
        emitter.off(e, fire);
        return fn.apply(null, arguments);
      };
      return emitter.on(e, fire);
    };
    emitter.destroy = function() {
      return events = {};
    };
  }
  return emitter;
};

xhook = EventEmitter(true);

xhook.EventEmitter = EventEmitter;

xhook[BEFORE] = function(handler, i) {
  if (handler.length < 1 || handler.length > 2) {
    throw "invalid hook";
  }
  return xhook[ON](BEFORE, handler, i);
};

xhook[AFTER] = function(handler, i) {
  if (handler.length < 2 || handler.length > 3) {
    throw "invalid hook";
  }
  return xhook[ON](AFTER, handler, i);
};

xhook.enable = function() {
  window[XMLHTTP] = XHookHttpRequest;
  if (NativeFormData) {
    window[FormData] = XHookFormData;
  }
};

xhook.disable = function() {
  window[XMLHTTP] = xhook[XMLHTTP];
  if (NativeFormData) {
    window[FormData] = NativeFormData;
  }
};

convertHeaders = xhook.headers = function(h, dest) {
  var header, headers, k, name, v, value, _i, _len, _ref;
  if (dest == null) {
    dest = {};
  }
  switch (typeof h) {
    case "object":
      headers = [];
      for (k in h) {
        v = h[k];
        name = k.toLowerCase();
        headers.push("" + name + ":\t" + v);
      }
      return headers.join('\n');
    case "string":
      headers = h.split('\n');
      for (_i = 0, _len = headers.length; _i < _len; _i++) {
        header = headers[_i];
        if (/([^:]+):\s*(.+)/.test(header)) {
          name = (_ref = RegExp.$1) != null ? _ref.toLowerCase() : void 0;
          value = RegExp.$2;
          if (dest[name] == null) {
            dest[name] = value;
          }
        }
      }
      return dest;
  }
};

NativeFormData = window[FormData];

XHookFormData = function(form) {
  var entries;
  this.fd = form ? new NativeFormData(form) : new NativeFormData();
  this.form = form;
  entries = [];
  Object.defineProperty(this, 'entries', {
    get: function() {
      var fentries;
      fentries = !form ? [] : slice(form.querySelectorAll("input,select")).filter(function(e) {
        var _ref;
        return ((_ref = e.type) !== 'checkbox' && _ref !== 'radio') || e.checked;
      }).map(function(e) {
        return [e.name, e.type === "file" ? e.files : e.value];
      });
      return fentries.concat(entries);
    }
  });
  this.append = (function(_this) {
    return function() {
      var args;
      args = slice(arguments);
      entries.push(args);
      return _this.fd.append.apply(_this.fd, args);
    };
  })(this);
};

if (NativeFormData) {
  xhook[FormData] = NativeFormData;
  window[FormData] = XHookFormData;
}

NativeXMLHttp = window[XMLHTTP];

xhook[XMLHTTP] = NativeXMLHttp;

XHookHttpRequest = window[XMLHTTP] = function() {
  var ABORTED, currentState, emitFinal, emitReadyState, event, facade, hasError, hasErrorHandler, readBody, readHead, request, response, setReadyState, status, transiting, writeBody, writeHead, xhr, _i, _len, _ref;
  ABORTED = -1;
  xhr = new xhook[XMLHTTP]();
  request = {};
  status = null;
  hasError = void 0;
  transiting = void 0;
  response = void 0;
  readHead = function() {
    var key, name, val, _ref;
    response.status = status || xhr.status;
    if (!(status === ABORTED && msie < 10)) {
      response.statusText = xhr.statusText;
    }
    if (status !== ABORTED) {
      _ref = convertHeaders(xhr.getAllResponseHeaders());
      for (key in _ref) {
        val = _ref[key];
        if (!response.headers[key]) {
          name = key.toLowerCase();
          response.headers[name] = val;
        }
      }
    }
  };
  readBody = function() {
    if (!xhr.responseType || xhr.responseType === "text") {
      response.text = xhr.responseText;
      response.data = xhr.responseText;
    } else if (xhr.responseType === "document") {
      response.xml = xhr.responseXML;
      response.data = xhr.responseXML;
    } else {
      response.data = xhr.response;
    }
    if ("responseURL" in xhr) {
      response.finalUrl = xhr.responseURL;
    }
  };
  writeHead = function() {
    facade.status = response.status;
    facade.statusText = response.statusText;
  };
  writeBody = function() {
    if ('text' in response) {
      facade.responseText = response.text;
    }
    if ('xml' in response) {
      facade.responseXML = response.xml;
    }
    if ('data' in response) {
      facade.response = response.data;
    }
    if ('finalUrl' in response) {
      facade.responseURL = response.finalUrl;
    }
  };
  emitReadyState = function(n) {
    while (n > currentState && currentState < 4) {
      facade[READY_STATE] = ++currentState;
      if (currentState === 1) {
        facade[FIRE]("loadstart", {});
      }
      if (currentState === 2) {
        writeHead();
      }
      if (currentState === 4) {
        writeHead();
        writeBody();
      }
      facade[FIRE]("readystatechange", {});
      if (currentState === 4) {
        setTimeout(emitFinal, 0);
      }
    }
  };
  emitFinal = function() {
    if (!hasError) {
      facade[FIRE]("load", {});
    }
    facade[FIRE]("loadend", {});
    if (hasError) {
      facade[READY_STATE] = 0;
    }
  };
  currentState = 0;
  setReadyState = function(n) {
    var hooks, process;
    if (n !== 4) {
      emitReadyState(n);
      return;
    }
    hooks = xhook.listeners(AFTER);
    process = function() {
      var hook;
      if (!hooks.length) {
        return emitReadyState(4);
      }
      hook = hooks.shift();
      if (hook.length === 2) {
        hook(request, response);
        return process();
      } else if (hook.length === 3 && request.async) {
        return hook(request, response, process);
      } else {
        return process();
      }
    };
    process();
  };
  facade = request.xhr = EventEmitter();
  xhr.onreadystatechange = function(event) {
    try {
      if (xhr[READY_STATE] === 2) {
        readHead();
      }
    } catch (_error) {}
    if (xhr[READY_STATE] === 4) {
      transiting = false;
      readHead();
      readBody();
    }
    setReadyState(xhr[READY_STATE]);
  };
  hasErrorHandler = function() {
    hasError = true;
  };
  facade[ON]('error', hasErrorHandler);
  facade[ON]('timeout', hasErrorHandler);
  facade[ON]('abort', hasErrorHandler);
  facade[ON]('progress', function() {
    if (currentState < 3) {
      setReadyState(3);
    } else {
      facade[FIRE]("readystatechange", {});
    }
  });
  if ('withCredentials' in xhr || xhook.addWithCredentials) {
    facade.withCredentials = false;
  }
  facade.status = 0;
  _ref = COMMON_EVENTS.concat(UPLOAD_EVENTS);
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    event = _ref[_i];
    facade["on" + event] = null;
  }
  facade.open = function(method, url, async, user, pass) {
    currentState = 0;
    hasError = false;
    transiting = false;
    request.headers = {};
    request.headerNames = {};
    request.status = 0;
    response = {};
    response.headers = {};
    request.method = method;
    request.url = url;
    request.async = async !== false;
    request.user = user;
    request.pass = pass;
    setReadyState(1);
  };
  facade.send = function(body) {
    var hooks, k, modk, process, send, _j, _len1, _ref1;
    _ref1 = ['type', 'timeout', 'withCredentials'];
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      k = _ref1[_j];
      modk = k === "type" ? "responseType" : k;
      if (modk in facade) {
        request[k] = facade[modk];
      }
    }
    request.body = body;
    send = function() {
      var header, value, _k, _len2, _ref2, _ref3;
      proxyEvents(COMMON_EVENTS, xhr, facade);
      if (facade.upload) {
        proxyEvents(COMMON_EVENTS.concat(UPLOAD_EVENTS), xhr.upload, facade.upload);
      }
      transiting = true;
      xhr.open(request.method, request.url, request.async, request.user, request.pass);
      _ref2 = ['type', 'timeout', 'withCredentials'];
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        k = _ref2[_k];
        modk = k === "type" ? "responseType" : k;
        if (k in request) {
          xhr[modk] = request[k];
        }
      }
      _ref3 = request.headers;
      for (header in _ref3) {
        value = _ref3[header];
        if (header) {
          xhr.setRequestHeader(header, value);
        }
      }
      if (request.body instanceof XHookFormData) {
        request.body = request.body.fd;
      }
      xhr.send(request.body);
    };
    hooks = xhook.listeners(BEFORE);
    process = function() {
      var done, hook;
      if (!hooks.length) {
        return send();
      }
      done = function(userResponse) {
        if (typeof userResponse === 'object' && (typeof userResponse.status === 'number' || typeof response.status === 'number')) {
          mergeObjects(userResponse, response);
          if (__indexOf.call(userResponse, 'data') < 0) {
            userResponse.data = userResponse.response || userResponse.text;
          }
          setReadyState(4);
          return;
        }
        process();
      };
      done.head = function(userResponse) {
        mergeObjects(userResponse, response);
        return setReadyState(2);
      };
      done.progress = function(userResponse) {
        mergeObjects(userResponse, response);
        return setReadyState(3);
      };
      hook = hooks.shift();
      if (hook.length === 1) {
        return done(hook(request));
      } else if (hook.length === 2 && request.async) {
        return hook(request, done);
      } else {
        return done();
      }
    };
    process();
  };
  facade.abort = function() {
    status = ABORTED;
    if (transiting) {
      xhr.abort();
    } else {
      facade[FIRE]('abort', {});
    }
  };
  facade.setRequestHeader = function(header, value) {
    var lName, name;
    lName = header != null ? header.toLowerCase() : void 0;
    name = request.headerNames[lName] = request.headerNames[lName] || header;
    if (request.headers[name]) {
      value = request.headers[name] + ', ' + value;
    }
    request.headers[name] = value;
  };
  facade.getResponseHeader = function(header) {
    var name;
    name = header != null ? header.toLowerCase() : void 0;
    return response.headers[name];
  };
  facade.getAllResponseHeaders = function() {
    return convertHeaders(response.headers);
  };
  if (xhr.overrideMimeType) {
    facade.overrideMimeType = function() {
      return xhr.overrideMimeType.apply(xhr, arguments);
    };
  }
  if (xhr.upload) {
    facade.upload = request.upload = EventEmitter();
  }
  return facade;
};

if (typeof define === "function" && define.amd) {
  define("xhook", [], function() {
    return xhook;
  });
} else {
  (this.exports || this).xhook = xhook;
}

}.call(this,window));
var CHECK_INTERVAL, COMPAT_VERSION, XD_CHECK, console, cookies, createSocket, currentOrigin, document, emitter, feature, frames, getFrame, guid, handleSocket, initMaster, initSlave, initdMaster, initdSlave, instOf, jsonEncode, location, log, logger, masters, onMessage, parseUrl, setupEmitter, slaves, slice, sockets, startPostMessage, strip, toRegExp, warn, xdomain, xhook, _i, _len, _ref;

initdMaster = false;

slaves = function(s) {
  var origin, path;
  if (!initdMaster) {
    initMaster();
  }
  for (origin in s) {
    path = s[origin];
    log("adding slave: " + origin);
    slaves[origin] = path;
  }
};

frames = {};

getFrame = function(origin, proxyPath) {
  var frame;
  if (frames[origin]) {
    return frames[origin];
  }
  frame = document.createElement("iframe");
  frame.id = frame.name = guid();
  log("creating iframe " + frame.id);
  frame.src = "" + origin + proxyPath;
  frame.setAttribute('style', 'display:none;');
  document.body.appendChild(frame);
  return frames[origin] = frame.contentWindow;
};

initMaster = function() {
  var convertFormData, convertToArrayBuffer, handleRequest;
  initdMaster = true;
  convertToArrayBuffer = function(args, done) {
    var isBlob, isFile, name, obj, reader;
    name = args[0], obj = args[1];
    isBlob = instOf(obj, 'Blob');
    isFile = instOf(obj, 'File');
    if (!(isBlob || isFile)) {
      return 0;
    }
    reader = new FileReader();
    reader.onload = function() {
      args[1] = null;
      if (isFile) {
        args[2] = obj.name;
      }
      return done(['XD_BLOB', args, this.result, obj.type]);
    };
    reader.readAsArrayBuffer(obj);
    return 1;
  };
  convertFormData = function(entries, send) {
    var c;
    entries.forEach(function(args, i) {
      var file, name, value, _i, _len;
      name = args[0], value = args[1];
      if (instOf(value, 'FileList')) {
        entries.splice(i, 1);
        for (_i = 0, _len = value.length; _i < _len; _i++) {
          file = value[_i];
          entries.splice(i, 0, [name, file]);
        }
      }
    });
    c = 0;
    entries.forEach(function(args, i) {
      c += convertToArrayBuffer(args, function(newargs) {
        entries[i] = newargs;
        if (--c === 0) {
          send();
        }
      });
    });
    if (c === 0) {
      send();
    }
  };
  handleRequest = function(request, socket) {
    var entries, obj, send;
    socket.on("xhr-event", function() {
      return request.xhr.dispatchEvent.apply(null, arguments);
    });
    socket.on("xhr-upload-event", function() {
      return request.xhr.upload.dispatchEvent.apply(null, arguments);
    });
    obj = strip(request);
    obj.headers = request.headers;
    if (request.withCredentials) {
      if (cookies.master) {
        obj.headers[cookies.master] = document.cookie;
      }
      obj.slaveCookie = cookies.slave;
    }
    send = function() {
      return socket.emit("request", obj);
    };
    if (request.body) {
      obj.body = request.body;
      if (instOf(obj.body, 'FormData')) {
        entries = obj.body.entries;
        obj.body = ["XD_FD", entries];
        convertFormData(entries, send);
        return;
      }
    }
    send();
  };
  if (!('addWithCredentials' in xhook)) {
    xhook.addWithCredentials = true;
  }
  return xhook.before(function(request, callback) {
    var frame, p, socket;
    p = parseUrl(request.url);
    if (!p || p.origin === currentOrigin) {
      return callback();
    }
    if (!slaves[p.origin]) {
      if (p) {
        log("no slave matching: '" + p.origin + "'");
      }
      return callback();
    }
    log("proxying request to slave: '" + p.origin + "'");
    if (request.async === false) {
      warn("sync not supported");
      return callback();
    }
    frame = getFrame(p.origin, slaves[p.origin]);
    socket = createSocket(guid(), frame);
    socket.on("response", function(resp) {
      callback(resp);
      return socket.close();
    });
    request.xhr.addEventListener('abort', function() {
      return socket.emit("abort");
    });
    if (socket.ready) {
      handleRequest(request, socket);
    } else {
      socket.once('ready', function() {
        return handleRequest(request, socket);
      });
    }
  });
};

initdSlave = false;

masters = function(m) {
  var origin, path;
  if (!initdSlave) {
    initSlave();
  }
  for (origin in m) {
    path = m[origin];
    log("adding master: " + origin);
    masters[origin] = path;
  }
};

handleSocket = null;

initSlave = function() {
  initdSlave = true;
  log("handling incoming sockets...");
  handleSocket = function(origin, socket) {
    var master, masterRegex, pathRegex, regex;
    if (origin === "null") {
      origin = "*";
    }
    pathRegex = null;
    for (master in masters) {
      regex = masters[master];
      try {
        masterRegex = toRegExp(master);
        if (masterRegex.test(origin)) {
          pathRegex = toRegExp(regex);
          break;
        }
      } catch (_error) {}
    }
    if (!pathRegex) {
      warn("blocked request from: '" + origin + "'");
      return;
    }
    socket.once("request", function(req) {
      var args, blob, entries, fd, k, p, v, xhr, _i, _len, _ref;
      log("request: " + req.method + " " + req.url);
      p = parseUrl(req.url);
      if (!(p && pathRegex.test(p.path))) {
        warn("blocked request to path: '" + p.path + "' by regex: " + pathRegex);
        socket.close();
        return;
      }
      xhr = new XMLHttpRequest();
      xhr.open(req.method, req.url);
      xhr.addEventListener("*", function(e) {
        return socket.emit('xhr-event', e.type, strip(e));
      });
      if (xhr.upload) {
        xhr.upload.addEventListener("*", function(e) {
          return socket.emit('xhr-upload-event', e.type, strip(e));
        });
      }
      socket.once("abort", function() {
        return xhr.abort();
      });
      xhr.onreadystatechange = function() {
        var resp;
        if (xhr.readyState !== 4) {
          return;
        }
        resp = {
          status: xhr.status,
          statusText: xhr.statusText,
          data: xhr.response,
          headers: xhook.headers(xhr.getAllResponseHeaders())
        };
        try {
          resp.text = xhr.responseText;
        } catch (_error) {}
        return socket.emit('response', resp);
      };
      if (req.withCredentials) {
        xhr.withCredentials = true;
        if (req.slaveCookie) {
          req.headers[req.slaveCookie] = document.cookie;
        }
      }
      if (req.timeout) {
        xhr.timeout = req.timeout;
      }
      if (req.type) {
        xhr.responseType = req.type;
      }
      _ref = req.headers;
      for (k in _ref) {
        v = _ref[k];
        xhr.setRequestHeader(k, v);
      }
      if (req.body instanceof Array && req.body[0] === "XD_FD") {
        fd = new xhook.FormData();
        entries = req.body[1];
        for (_i = 0, _len = entries.length; _i < _len; _i++) {
          args = entries[_i];
          if (args[0] === "XD_BLOB" && args.length === 4) {
            blob = new Blob([args[2]], {
              type: args[3]
            });
            args = args[1];
            args[1] = blob;
          }
          fd.append.apply(fd, args);
        }
        req.body = fd;
      }
      xhr.send(req.body || null);
    });
    log("slave listening for requests on socket: " + socket.id);
  };
  if (window === window.parent) {
    return warn("slaves must be in an iframe");
  } else {
    return window.parent.postMessage("XDPING_" + COMPAT_VERSION, '*');
  }
};

XD_CHECK = "XD_CHECK";

sockets = {};

jsonEncode = true;

createSocket = function(id, frame) {
  var check, checks, emit, pendingEmits, ready, sock;
  ready = false;
  sock = sockets[id] = xhook.EventEmitter(true);
  sock.id = id;
  sock.once('close', function() {
    sock.destroy();
    return sock.close();
  });
  pendingEmits = [];
  sock.emit = function() {
    var args, extra;
    args = slice(arguments);
    extra = typeof args[1] === "string" ? " -> " + args[1] : "";
    log("send socket: " + id + ": " + args[0] + extra);
    args.unshift(id);
    if (ready) {
      emit(args);
    } else {
      pendingEmits.push(args);
    }
  };
  emit = function(args) {
    if (jsonEncode) {
      args = JSON.stringify(args);
    }
    frame.postMessage(args, "*");
  };
  sock.close = function() {
    sock.emit('close');
    log("close socket: " + id);
    sockets[id] = null;
  };
  sock.once(XD_CHECK, function(obj) {
    jsonEncode = typeof obj === "string";
    ready = sock.ready = true;
    sock.emit('ready');
    log("ready socket: " + id + " (emit #" + pendingEmits.length + " pending)");
    while (pendingEmits.length) {
      emit(pendingEmits.shift());
    }
  });
  checks = 0;
  check = (function(_this) {
    return function() {
      frame.postMessage([id, XD_CHECK, {}], "*");
      if (ready) {
        return;
      }
      if (checks++ >= xdomain.timeout / CHECK_INTERVAL) {
        warn("Timeout waiting on iframe socket");
        emitter.fire("timeout");
        sock.fire("abort");
      } else {
        setTimeout(check, CHECK_INTERVAL);
      }
    };
  })(this);
  setTimeout(check);
  log("new socket: " + id);
  return sock;
};

onMessage = function(fn) {
  if (document.addEventListener) {
    return window.addEventListener("message", fn);
  } else {
    return window.attachEvent("onmessage", fn);
  }
};

startPostMessage = function() {
  return onMessage(function(e) {
    var d, extra, id, sock;
    d = e.data;
    if (typeof d === "string") {
      if (/^XDPING(_(V\d+))?$/.test(d) && RegExp.$2 !== COMPAT_VERSION) {
        return warn("your master is not compatible with your slave, check your xdomain.js version");
      } else if (/^xdomain-/.test(d)) {
        d = d.split(",");
      } else if (jsonEncode) {
        try {
          d = JSON.parse(d);
        } catch (_error) {
          return;
        }
      }
    }
    if (!(d instanceof Array)) {
      return;
    }
    id = d.shift();
    if (!/^xdomain-/.test(id)) {
      return;
    }
    sock = sockets[id];
    if (sock === null) {
      return;
    }
    if (sock === undefined) {
      if (!handleSocket) {
        return;
      }
      sock = createSocket(id, e.source);
      handleSocket(e.origin, sock);
    }
    extra = typeof d[1] === "string" ? " -> " + d[1] : "";
    log("receive socket: " + id + ": " + d[0] + extra);
    sock.fire.apply(sock, d);
  });
};

'use strict';

xhook = (this.exports || this).xhook;

xdomain = function(o) {
  if (!o) {
    return;
  }
  if (o.masters) {
    masters(o.masters);
  }
  if (o.slaves) {
    slaves(o.slaves);
  }
};

xdomain.masters = masters;

xdomain.slaves = slaves;

xdomain.debug = false;

xdomain.timeout = 15e3;

CHECK_INTERVAL = 100;

cookies = xdomain.cookies = {
  master: "Master-Cookie",
  slave: "Slave-Cookie"
};

document = window.document;

location = window.location;

currentOrigin = xdomain.origin = location.protocol + '//' + location.host;

guid = function() {
  return 'xdomain-' + Math.round(Math.random() * Math.pow(2, 32)).toString(16);
};

slice = function(o, n) {
  return Array.prototype.slice.call(o, n);
};

console = window.console || {};

emitter = null;

setupEmitter = function() {
  emitter = xhook.EventEmitter(true);
  xdomain.on = emitter.on;
  xdomain.off = emitter.off;
};

if (xhook) {
  setupEmitter();
}

logger = function(type) {
  return function(str) {
    str = "xdomain (" + currentOrigin + "): " + str;
    emitter.fire(type, str);
    if (type === 'log' && !xdomain.debug) {
      return;
    }
    if (type in xdomain) {
      xdomain[type](str);
    } else if (type in console) {
      console[type](str);
    } else if (type === 'warn') {
      alert(str);
    }
  };
};

log = logger('log');

warn = logger('warn');

_ref = ['postMessage', 'JSON'];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  feature = _ref[_i];
  if (!window[feature]) {
    warn("requires '" + feature + "' and this browser does not support it");
    return;
  }
}

instOf = function(obj, global) {
  if (!(global in window)) {
    return false;
  }
  return obj instanceof window[global];
};

COMPAT_VERSION = "V1";

parseUrl = xdomain.parseUrl = function(url) {
  if (/^((https?:)?\/\/[^\/\?]+)(\/.*)?/.test(url)) {
    return {
      origin: (RegExp.$2 ? '' : location.protocol) + RegExp.$1,
      path: RegExp.$3
    };
  } else {
    log("failed to parse absolute url: " + url);
    return null;
  }
};

toRegExp = function(obj) {
  var str;
  if (obj instanceof RegExp) {
    return obj;
  }
  str = obj.toString().replace(/\W/g, function(str) {
    return "\\" + str;
  }).replace(/\\\*/g, ".*");
  return new RegExp("^" + str + "$");
};

strip = function(src) {
  var dst, k, v, _ref1;
  dst = {};
  for (k in src) {
    if (k === "returnValue") {
      continue;
    }
    v = src[k];
    if ((_ref1 = typeof v) !== "function" && _ref1 !== "object") {
      dst[k] = v;
    }
  }
  return dst;
};

(function() {
  var attrs, fn, k, prefix, script, _j, _k, _len1, _len2, _ref1, _ref2;
  attrs = {
    debug: function(value) {
      if (typeof value !== "string") {
        return;
      }
      return xdomain.debug = value !== "false";
    },
    slave: function(value) {
      var p, s;
      if (!value) {
        return;
      }
      p = parseUrl(value);
      if (!p) {
        return;
      }
      s = {};
      s[p.origin] = p.path;
      return slaves(s);
    },
    master: function(value) {
      var m, p;
      if (!value) {
        return;
      }
      if (value === "*") {
        p = {
          origin: "*",
          path: "*"
        };
      } else {
        p = parseUrl(value);
      }
      if (!p) {
        return;
      }
      m = {};
      m[p.origin] = p.path.replace(/^\//, "") ? p.path : "*";
      return masters(m);
    }
  };
  _ref1 = document.getElementsByTagName("script");
  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
    script = _ref1[_j];
    if (/xdomain/.test(script.src)) {
      _ref2 = ['', 'data-'];
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        prefix = _ref2[_k];
        for (k in attrs) {
          fn = attrs[k];
          fn(script.getAttribute(prefix + k));
        }
      }
    }
  }
})();

startPostMessage();

if (typeof define === "function" && define.amd) {
  define("xdomain", ["xhook"], function(xh) {
    xhook = xh;
    setupEmitter();
    return xdomain;
  });
} else {
  (this.exports || this).xdomain = xdomain;
}

}.call(this,window));