(function() {
  var BCSocket, Connection, Doc, MicroEvent, SockJS, Socket, WebSocket, append, bootstrapTransform, checkValidComponent, checkValidOp, exports, hasBCSocket, hasSockJS, hasWS, invertComponent, nextTick, strInject, text, transformComponent, transformPosition, types, useSockJS, useWS;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  window.sharejs = exports = {
    'version': '0.5.0'
  };
  if (typeof WEB === 'undefined') {
    window.WEB = true;
  }
  nextTick = typeof WEB !== "undefined" && WEB !== null ? function(fn) {
    return setTimeout(fn, 0);
  } : process['nextTick'];
  MicroEvent = (function() {
    function MicroEvent() {}
    MicroEvent.prototype.on = function(event, fct) {
      var _base;
      this._events || (this._events = {});
      (_base = this._events)[event] || (_base[event] = []);
      this._events[event].push(fct);
      return this;
    };
    MicroEvent.prototype.removeListener = function(event, fct) {
      var i, listeners, _base;
      this._events || (this._events = {});
      listeners = ((_base = this._events)[event] || (_base[event] = []));
      i = 0;
      while (i < listeners.length) {
        if (listeners[i] === fct) {
          listeners[i] = void 0;
        }
        i++;
      }
      nextTick(__bind(function() {
        var x;
        return this._events[event] = (function() {
          var _i, _len, _ref, _results;
          _ref = this._events[event];
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            x = _ref[_i];
            if (x) {
              _results.push(x);
            }
          }
          return _results;
        }).call(this);
      }, this));
      return this;
    };
    MicroEvent.prototype.emit = function() {
      var args, event, fn, _i, _len, _ref, _ref2;
      event = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (!((_ref = this._events) != null ? _ref[event] : void 0)) {
        return this;
      }
      _ref2 = this._events[event];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        fn = _ref2[_i];
        if (fn) {
          fn.apply(this, args);
        }
      }
      return this;
    };
    return MicroEvent;
  })();
  MicroEvent.mixin = function(obj) {
    var proto;
    proto = obj.prototype || obj;
    proto.on = MicroEvent.prototype.on;
    proto.removeListener = MicroEvent.prototype.removeListener;
    proto.emit = MicroEvent.prototype.emit;
    return obj;
  };
  if (typeof WEB === "undefined" || WEB === null) {
    module.exports = MicroEvent;
  }
  exports['_bt'] = bootstrapTransform = function(type, transformComponent, checkValidOp, append) {
    var transformComponentX, transformX;
    transformComponentX = function(left, right, destLeft, destRight) {
      transformComponent(destLeft, left, right, 'left');
      return transformComponent(destRight, right, left, 'right');
    };
    type.transformX = type['transformX'] = transformX = function(leftOp, rightOp) {
      var k, l, l_, newLeftOp, newRightOp, nextC, r, r_, rightComponent, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2;
      checkValidOp(leftOp);
      checkValidOp(rightOp);
      newRightOp = [];
      for (_i = 0, _len = rightOp.length; _i < _len; _i++) {
        rightComponent = rightOp[_i];
        newLeftOp = [];
        k = 0;
        while (k < leftOp.length) {
          nextC = [];
          transformComponentX(leftOp[k], rightComponent, newLeftOp, nextC);
          k++;
          if (nextC.length === 1) {
            rightComponent = nextC[0];
          } else if (nextC.length === 0) {
            _ref = leftOp.slice(k);
            for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
              l = _ref[_j];
              append(newLeftOp, l);
            }
            rightComponent = null;
            break;
          } else {
            _ref2 = transformX(leftOp.slice(k), nextC), l_ = _ref2[0], r_ = _ref2[1];
            for (_k = 0, _len3 = l_.length; _k < _len3; _k++) {
              l = l_[_k];
              append(newLeftOp, l);
            }
            for (_l = 0, _len4 = r_.length; _l < _len4; _l++) {
              r = r_[_l];
              append(newRightOp, r);
            }
            rightComponent = null;
            break;
          }
        }
        if (rightComponent != null) {
          append(newRightOp, rightComponent);
        }
        leftOp = newLeftOp;
      }
      return [leftOp, newRightOp];
    };
    return type.transform = type['transform'] = function(op, otherOp, type) {
      var left, right, _, _ref, _ref2;
      if (!(type === 'left' || type === 'right')) {
        throw new Error("type must be 'left' or 'right'");
      }
      if (otherOp.length === 0) {
        return op;
      }
      if (op.length === 1 && otherOp.length === 1) {
        return transformComponent([], op[0], otherOp[0], type);
      }
      if (type === 'left') {
        _ref = transformX(op, otherOp), left = _ref[0], _ = _ref[1];
        return left;
      } else {
        _ref2 = transformX(otherOp, op), _ = _ref2[0], right = _ref2[1];
        return right;
      }
    };
  };
  if (typeof WEB === 'undefined') {
    exports.bootstrapTransform = bootstrapTransform;
  }
  text = {};
  text.name = 'text';
  text.create = function() {
    return '';
  };
  strInject = function(s1, pos, s2) {
    return s1.slice(0, pos) + s2 + s1.slice(pos);
  };
  checkValidComponent = function(c) {
    var d_type, i_type;
    if (typeof c.p !== 'number') {
      throw new Error('component missing position field');
    }
    i_type = typeof c.i;
    d_type = typeof c.d;
    if (!((i_type === 'string') ^ (d_type === 'string'))) {
      throw new Error('component needs an i or d field');
    }
    if (!(c.p >= 0)) {
      throw new Error('position cannot be negative');
    }
  };
  checkValidOp = function(op) {
    var c, _i, _len;
    for (_i = 0, _len = op.length; _i < _len; _i++) {
      c = op[_i];
      checkValidComponent(c);
    }
    return true;
  };
  text.apply = function(snapshot, op) {
    var component, deleted, _i, _len;
    checkValidOp(op);
    for (_i = 0, _len = op.length; _i < _len; _i++) {
      component = op[_i];
      if (component.i != null) {
        snapshot = strInject(snapshot, component.p, component.i);
      } else {
        deleted = snapshot.slice(component.p, component.p + component.d.length);
        if (component.d !== deleted) {
          throw new Error("Delete component '" + component.d + "' does not match deleted text '" + deleted + "'");
        }
        snapshot = snapshot.slice(0, component.p) + snapshot.slice(component.p + component.d.length);
      }
    }
    return snapshot;
  };
  text._append = append = function(newOp, c) {
    var last, _ref, _ref2;
    if (c.i === '' || c.d === '') {
      return;
    }
    if (newOp.length === 0) {
      return newOp.push(c);
    } else {
      last = newOp[newOp.length - 1];
      if ((last.i != null) && (c.i != null) && (last.p <= (_ref = c.p) && _ref <= (last.p + last.i.length))) {
        return newOp[newOp.length - 1] = {
          i: strInject(last.i, c.p - last.p, c.i),
          p: last.p
        };
      } else if ((last.d != null) && (c.d != null) && (c.p <= (_ref2 = last.p) && _ref2 <= (c.p + c.d.length))) {
        return newOp[newOp.length - 1] = {
          d: strInject(c.d, last.p - c.p, last.d),
          p: c.p
        };
      } else {
        return newOp.push(c);
      }
    }
  };
  text.compose = function(op1, op2) {
    var c, newOp, _i, _len;
    checkValidOp(op1);
    checkValidOp(op2);
    newOp = op1.slice();
    for (_i = 0, _len = op2.length; _i < _len; _i++) {
      c = op2[_i];
      append(newOp, c);
    }
    return newOp;
  };
  text.compress = function(op) {
    return text.compose([], op);
  };
  text.normalize = function(op) {
    var c, newOp, _i, _len, _ref;
    newOp = [];
    if ((op.i != null) || (op.p != null)) {
      op = [op];
    }
    for (_i = 0, _len = op.length; _i < _len; _i++) {
      c = op[_i];
            if ((_ref = c.p) != null) {
        _ref;
      } else {
        c.p = 0;
      };
      append(newOp, c);
    }
    return newOp;
  };
  transformPosition = function(pos, c, insertAfter) {
    if (c.i != null) {
      if (c.p < pos || (c.p === pos && insertAfter)) {
        return pos + c.i.length;
      } else {
        return pos;
      }
    } else {
      if (pos <= c.p) {
        return pos;
      } else if (pos <= c.p + c.d.length) {
        return c.p;
      } else {
        return pos - c.d.length;
      }
    }
  };
  text.transformCursor = function(position, op, side) {
    var c, insertAfter, _i, _len;
    insertAfter = side === 'right';
    for (_i = 0, _len = op.length; _i < _len; _i++) {
      c = op[_i];
      position = transformPosition(position, c, insertAfter);
    }
    return position;
  };
  text._tc = transformComponent = function(dest, c, otherC, side) {
    var cIntersect, intersectEnd, intersectStart, newC, otherIntersect, s;
    checkValidOp([c]);
    checkValidOp([otherC]);
    if (c.i != null) {
      append(dest, {
        i: c.i,
        p: transformPosition(c.p, otherC, side === 'right')
      });
    } else {
      if (otherC.i != null) {
        s = c.d;
        if (c.p < otherC.p) {
          append(dest, {
            d: s.slice(0, otherC.p - c.p),
            p: c.p
          });
          s = s.slice(otherC.p - c.p);
        }
        if (s !== '') {
          append(dest, {
            d: s,
            p: c.p + otherC.i.length
          });
        }
      } else {
        if (c.p >= otherC.p + otherC.d.length) {
          append(dest, {
            d: c.d,
            p: c.p - otherC.d.length
          });
        } else if (c.p + c.d.length <= otherC.p) {
          append(dest, c);
        } else {
          newC = {
            d: '',
            p: c.p
          };
          if (c.p < otherC.p) {
            newC.d = c.d.slice(0, otherC.p - c.p);
          }
          if (c.p + c.d.length > otherC.p + otherC.d.length) {
            newC.d += c.d.slice(otherC.p + otherC.d.length - c.p);
          }
          intersectStart = Math.max(c.p, otherC.p);
          intersectEnd = Math.min(c.p + c.d.length, otherC.p + otherC.d.length);
          cIntersect = c.d.slice(intersectStart - c.p, intersectEnd - c.p);
          otherIntersect = otherC.d.slice(intersectStart - otherC.p, intersectEnd - otherC.p);
          if (cIntersect !== otherIntersect) {
            throw new Error('Delete ops delete different text in the same region of the document');
          }
          if (newC.d !== '') {
            newC.p = transformPosition(newC.p, otherC);
            append(dest, newC);
          }
        }
      }
    }
    return dest;
  };
  invertComponent = function(c) {
    if (c.i != null) {
      return {
        d: c.i,
        p: c.p
      };
    } else {
      return {
        i: c.d,
        p: c.p
      };
    }
  };
  text.invert = function(op) {
    var c, _i, _len, _ref, _results;
    _ref = op.slice().reverse();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      c = _ref[_i];
      _results.push(invertComponent(c));
    }
    return _results;
  };
  if (typeof WEB !== "undefined" && WEB !== null) {
    exports.types || (exports.types = {});
    bootstrapTransform(text, transformComponent, checkValidOp, append);
    exports.types.text = text;
  } else {
    module.exports = text;
    require('./helpers').bootstrapTransform(text, transformComponent, checkValidOp, append);
  }
  if (typeof WEB === 'undefined') {
    text = require('./text');
  }
  text.api = {
    provides: {
      text: true
    },
    getLength: function() {
      return this.snapshot.length;
    },
    getText: function() {
      return this.snapshot;
    },
    insert: function(pos, text, callback) {
      var op;
      op = [
        {
          p: pos,
          i: text
        }
      ];
      this.submitOp(op, callback);
      return op;
    },
    del: function(pos, length, callback) {
      var op;
      op = [
        {
          p: pos,
          d: this.snapshot.slice(pos, pos + length)
        }
      ];
      this.submitOp(op, callback);
      return op;
    },
    _register: function() {
      return this.on('remoteop', function(op) {
        var component, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = op.length; _i < _len; _i++) {
          component = op[_i];
          _results.push(component.i !== void 0 ? this.emit('insert', component.p, component.i) : this.emit('delete', component.p, component.d));
        }
        return _results;
      });
    }
  };
  if (typeof WEB === "undefined" || WEB === null) {
    types = require('../types');
  }
  if (typeof WEB !== "undefined" && WEB !== null) {
    exports.extendDoc = function(name, fn) {
      return Doc.prototype[name] = fn;
    };
  }
  Doc = (function() {
    function Doc(connection, name, openData) {
      this.connection = connection;
      this.name = name;
      this.shout = __bind(this.shout, this);;
      this.flush = __bind(this.flush, this);;
      openData || (openData = {});
      this.version = openData.v;
      this.snapshot = openData.snaphot;
      if (openData.type) {
        this._setType(openData.type);
      }
      this.state = 'closed';
      this.autoOpen = false;
      this._create = openData.create;
      this.inflightOp = null;
      this.inflightCallbacks = [];
      this.inflightSubmittedIds = [];
      this.pendingOp = null;
      this.pendingCallbacks = [];
      this.serverOps = {};
    }
    Doc.prototype._xf = function(client, server) {
      var client_, server_;
      if (this.type.transformX) {
        return this.type.transformX(client, server);
      } else {
        client_ = this.type.transform(client, server, 'left');
        server_ = this.type.transform(server, client, 'right');
        return [client_, server_];
      }
    };
    Doc.prototype._otApply = function(docOp, isRemote) {
      var oldSnapshot;
      oldSnapshot = this.snapshot;
      this.snapshot = this.type.apply(this.snapshot, docOp);
      this.emit('change', docOp, oldSnapshot);
      if (isRemote) {
        return this.emit('remoteop', docOp, oldSnapshot);
      }
    };
    Doc.prototype._connectionStateChanged = function(state, data) {
      switch (state) {
        case 'disconnected':
          this.state = 'closed';
          if (this.inflightOp) {
            this.inflightSubmittedIds.push(this.connection.id);
          }
          this.emit('closed');
          break;
        case 'ok':
          if (this.autoOpen) {
            this.open();
          }
          break;
        case 'stopped':
          if (typeof this._openCallback === "function") {
            this._openCallback(data);
          }
      }
      return this.emit(state, data);
    };
    Doc.prototype._setType = function(type) {
      var k, v, _ref;
      if (typeof type === 'string') {
        type = types[type];
      }
      if (!(type && type.compose)) {
        throw new Error('Support for types without compose() is not implemented');
      }
      this.type = type;
      if (type.api) {
        _ref = type.api;
        for (k in _ref) {
          v = _ref[k];
          this[k] = v;
        }
        return typeof this._register === "function" ? this._register() : void 0;
      } else {
        return this.provides = {};
      }
    };
    Doc.prototype._onMessage = function(msg) {
      var callback, docOp, error, oldInflightOp, op, path, response, undo, value, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7;
      if (msg.open === true) {
        this.state = 'open';
        this._create = false;
        if (this.created == null) {
          this.created = !!msg.create;
        }
        if (msg.type) {
          this._setType(msg.type);
        }
        if (msg.create) {
          this.created = true;
          this.snapshot = this.type.create();
        } else {
          if (this.created !== true) {
            this.created = false;
          }
          if (msg.snapshot !== void 0) {
            this.snapshot = msg.snapshot;
          }
        }
        if (msg.v != null) {
          this.version = msg.v;
        }
        if (this.inflightOp) {
          response = {
            doc: this.name,
            op: this.inflightOp,
            v: this.version
          };
          if (this.inflightSubmittedIds.length) {
            response.dupIfSource = this.inflightSubmittedIds;
          }
          this.connection.send(response);
        } else {
          this.flush();
        }
        this.emit('open');
        return typeof this._openCallback === "function" ? this._openCallback(null) : void 0;
      } else if (msg.open === false) {
        if (msg.error) {
          if (typeof console !== "undefined" && console !== null) {
            console.error("Could not open document: " + msg.error);
          }
          this.emit('error', msg.error);
          if (typeof this._openCallback === "function") {
            this._openCallback(msg.error);
          }
        }
        this.state = 'closed';
        this.emit('closed');
        if (typeof this._closeCallback === "function") {
          this._closeCallback();
        }
        return this._closeCallback = null;
      } else if (msg.op === null && error === 'Op already submitted') {
        ;
      } else if ((msg.op === void 0 && msg.v !== void 0) || (msg.op && (_ref = msg.meta.source, __indexOf.call(this.inflightSubmittedIds, _ref) >= 0))) {
        oldInflightOp = this.inflightOp;
        this.inflightOp = null;
        this.inflightSubmittedIds.length = 0;
        error = msg.error;
        if (error) {
          if (this.type.invert) {
            undo = this.type.invert(oldInflightOp);
            if (this.pendingOp) {
              _ref2 = this._xf(this.pendingOp, undo), this.pendingOp = _ref2[0], undo = _ref2[1];
            }
            this._otApply(undo, true);
          } else {
            this.emit('error', "Op apply failed (" + error + ") and the op could not be reverted");
          }
          _ref3 = this.inflightCallbacks;
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            callback = _ref3[_i];
            callback(error);
          }
        } else {
          if (msg.v !== this.version) {
            throw new Error('Invalid version from server');
          }
          this.serverOps[this.version] = oldInflightOp;
          this.version++;
          this.emit('acknowledge', oldInflightOp);
          _ref4 = this.inflightCallbacks;
          for (_j = 0, _len2 = _ref4.length; _j < _len2; _j++) {
            callback = _ref4[_j];
            callback(null, oldInflightOp);
          }
        }
        return this.flush();
      } else if (msg.op) {
        if (msg.v < this.version) {
          return;
        }
        if (msg.doc !== this.name) {
          return this.emit('error', "Expected docName '" + this.name + "' but got " + msg.doc);
        }
        if (msg.v !== this.version) {
          return this.emit('error', "Expected version " + this.version + " but got " + msg.v);
        }
        op = msg.op;
        this.serverOps[this.version] = op;
        docOp = op;
        if (this.inflightOp !== null) {
          _ref5 = this._xf(this.inflightOp, docOp), this.inflightOp = _ref5[0], docOp = _ref5[1];
        }
        if (this.pendingOp !== null) {
          _ref6 = this._xf(this.pendingOp, docOp), this.pendingOp = _ref6[0], docOp = _ref6[1];
        }
        this.version++;
        return this._otApply(docOp, true);
      } else if (msg.meta) {
        _ref7 = msg.meta, path = _ref7.path, value = _ref7.value;
        switch (path != null ? path[0] : void 0) {
          case 'shout':
            return this.emit('shout', value);
          default:
            return typeof console !== "undefined" && console !== null ? console.warn('Unhandled meta op:', msg) : void 0;
        }
      } else {
        return typeof console !== "undefined" && console !== null ? console.warn('Unhandled document message:', msg) : void 0;
      }
    };
    Doc.prototype.flush = function() {
      if (!(this.connection.state === 'ok' && this.inflightOp === null && this.pendingOp !== null)) {
        return;
      }
      this.inflightOp = this.pendingOp;
      this.inflightCallbacks = this.pendingCallbacks;
      this.pendingOp = null;
      this.pendingCallbacks = [];
      return this.connection.send({
        doc: this.name,
        op: this.inflightOp,
        v: this.version
      });
    };
    Doc.prototype.submitOp = function(op, callback) {
      if (this.type.normalize != null) {
        op = this.type.normalize(op);
      }
      this.snapshot = this.type.apply(this.snapshot, op);
      if (this.pendingOp !== null) {
        this.pendingOp = this.type.compose(this.pendingOp, op);
      } else {
        this.pendingOp = op;
      }
      if (callback) {
        this.pendingCallbacks.push(callback);
      }
      this.emit('change', op);
      return setTimeout(this.flush, 0);
    };
    Doc.prototype.shout = function(msg) {
      return this.connection.send({
        doc: this.name,
        meta: {
          path: ['shout'],
          value: msg
        }
      });
    };
    Doc.prototype.open = function(callback) {
      var message;
      this.autoOpen = true;
      if (this.state !== 'closed') {
        return;
      }
      message = {
        doc: this.name,
        open: true
      };
      if (this.snapshot === void 0) {
        message.snapshot = null;
      }
      if (this.type) {
        message.type = this.type.name;
      }
      if (this.version != null) {
        message.v = this.version;
      }
      if (this._create) {
        message.create = true;
      }
      this.connection.send(message);
      this.state = 'opening';
      return this._openCallback = __bind(function(error) {
        this._openCallback = null;
        return typeof callback === "function" ? callback(error) : void 0;
      }, this);
    };
    Doc.prototype.close = function(callback) {
      this.autoOpen = false;
      if (this.state === 'closed') {
        return typeof callback === "function" ? callback() : void 0;
      }
      this.connection.send({
        doc: this.name,
        open: false
      });
      this.state = 'closed';
      this.emit('closing');
      return this._closeCallback = callback;
    };
    return Doc;
  })();
  if (typeof WEB === "undefined" || WEB === null) {
    MicroEvent = require('./microevent');
  }
  MicroEvent.mixin(Doc);
  exports.Doc = Doc;
  if (typeof WEB !== "undefined" && WEB !== null) {
    types = exports.types;
    BCSocket = window.BCSocket, SockJS = window.SockJS, WebSocket = window.WebSocket;
  } else {
    types = require('../types');
    BCSocket = require('browserchannel').BCSocket;
    Doc = require('./doc').Doc;
  }
  Socket = (function() {
    function Socket(host) {
      this.send = __bind(this.send, this);;      this.buffer = [];
      this.connected = false;
      this.socket = new WebSocket(host);
      this.socket.onopen = __bind(function() {
        this.connected = true;
        this.onopen();
        return this.flush();
      }, this);
      this.socket.onerror = __bind(function(error) {
        return this.onerror(error);
      }, this);
      this.socket.onmessage = __bind(function(message) {
        console.info("Socket Message " + message);
        return this.onmessage(message);
      }, this);
      this.socket.onclose = __bind(function() {
        this.connected = false;
        return this.onclose();
      }, this);
    }
    Socket.prototype.flush = function() {
      var message, _i, _len, _ref;
      _ref = this.buffer;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        message = _ref[_i];
        this.send(message);
      }
      return this.buffer = [];
    };
    Socket.prototype.close = function() {
      return this.socket.close();
    };
    Socket.prototype.send = function(message) {
      if (this.connected) {
        if (message.constructor !== String) {
          message = JSON.stringify(message);
        }
        console.log("Sending: " + message);
        return this.socket.send(message);
      } else {
        return this.buffer.push(message);
      }
    };
    Socket.prototype.onmessage = function() {};
    Socket.prototype.onclose = function() {};
    Socket.prototype.onopen = function() {};
    Socket.prototype.onconnecting = function() {};
    Socket.prototype.onerror = function() {};
    return Socket;
  })();
  Connection = (function() {
    function Connection(host, authentication) {
      this.docs = {};
      this.numDocs = 0;
      this.state = 'connecting';
      this.socket = typeof useSockJS !== "undefined" && useSockJS !== null ? new SockJS(host) : typeof useWS !== "undefined" && useWS !== null ? new Socket(host) : new BCSocket(host, {
        reconnect: true
      });
      this.socket.send({
        "auth": authentication ? authentication : null
      });
      this.socket.onmessage = __bind(function(msg) {
        var docName;
        if ((typeof useSockJS !== "undefined" && useSockJS !== null) || (typeof useWS !== "undefined" && useWS !== null)) {
          msg = JSON.parse(msg.data);
        }
        if (msg.auth === null) {
          this.lastError = msg.error;
          this.disconnect();
          return this.emit('connect failed', msg.error);
        } else if (msg.auth) {
          this.id = msg.auth;
          this.setState('ok');
          return;
        }
        docName = msg.doc;
        if (docName !== void 0) {
          this.lastReceivedDoc = docName;
        } else {
          msg.doc = docName = this.lastReceivedDoc;
        }
        if (this.docs[docName]) {
          return this.docs[docName]._onMessage(msg);
        } else {
          return typeof console !== "undefined" && console !== null ? console.error('Unhandled message', msg) : void 0;
        }
      }, this);
      this.connected = false;
      this.socket.onclose = __bind(function(reason) {
        console.warn('onclose', reason);
        this.setState('disconnected', reason);
        if (reason === 'Closed' || reason === 'Stopped by server') {
          return this.setState('stopped', this.lastError || reason);
        }
      }, this);
      this.socket.onerror = __bind(function(e) {
        console.warn('onerror', e);
        return this.emit('error', e);
      }, this);
      this.socket.onopen = __bind(function() {
        console.warn('onopen');
        this.lastError = this.lastReceivedDoc = this.lastSentDoc = null;
        return this.setState('handshaking');
      }, this);
      this.socket.onconnecting = __bind(function() {
        console.warn('connecting');
        return this.setState('connecting');
      }, this);
    }
    Connection.prototype.setState = function(state, data) {
      var doc, docName, _ref, _results;
      if (this.state === state) {
        return;
      }
      this.state = state;
      if (state === 'disconnected') {
        delete this.id;
      }
      this.emit(state, data);
      _ref = this.docs;
      _results = [];
      for (docName in _ref) {
        doc = _ref[docName];
        _results.push(doc._connectionStateChanged(state, data));
      }
      return _results;
    };
    Connection.prototype.send = function(data) {
      var docName;
      docName = data.doc;
      if (docName === this.lastSentDoc) {
        delete data.doc;
      } else {
        this.lastSentDoc = docName;
      }
      if ((typeof useSockJS !== "undefined" && useSockJS !== null) || (typeof useWS !== "undefined" && useWS !== null)) {
        data = JSON.stringify(data);
      }
      return this.socket.send(data);
    };
    Connection.prototype.disconnect = function() {
      return this.socket.close();
    };
    Connection.prototype.makeDoc = function(name, data, callback) {
      var doc;
      if (this.docs[name]) {
        throw new Error("Doc " + name + " already open");
      }
      doc = new Doc(this, name, data);
      this.docs[name] = doc;
      return doc.open(__bind(function(error) {
        if (error) {
          delete this.docs[name];
        }
        return callback(error, (!error ? doc : void 0));
      }, this));
    };
    Connection.prototype.openExisting = function(docName, callback) {
      var doc;
      if (this.state === 'stopped') {
        return callback('connection closed');
      }
      if (this.docs[docName]) {
        return callback(null, this.docs[docName]);
      }
      return doc = this.makeDoc(docName, {}, callback);
    };
    Connection.prototype.open = function(docName, type, callback) {
      var doc;
      if (this.state === 'stopped') {
        return callback('connection closed');
      }
      if (this.state === 'connecting') {
        this.on('handshaking', function() {
          return this.open(docName, type, callback);
        });
        return;
      }
      if (typeof type === 'function') {
        callback = type;
        type = 'text';
      }
      callback || (callback = function() {});
      if (typeof type === 'string') {
        type = types[type];
      }
      if (!type) {
        throw new Error("OT code for document type missing");
      }
      if (docName == null) {
        throw new Error('Server-generated random doc names are not currently supported');
      }
      if (this.docs[docName]) {
        doc = this.docs[docName];
        if (doc.type === type) {
          callback(null, doc);
        } else {
          callback('Type mismatch', doc);
        }
        return;
      }
      return this.makeDoc(docName, {
        create: true,
        type: type.name
      }, callback);
    };
    return Connection;
  })();
  if (typeof WEB === "undefined" || WEB === null) {
    MicroEvent = require('./microevent');
  }
  MicroEvent.mixin(Connection);
  exports.Connection = Connection;
  if (typeof WEB !== "undefined" && WEB !== null) {
    hasBCSocket = window.BCSocket !== void 0;
    hasSockJS = window.SockJS !== void 0;
    hasWS = window.WebSocket !== void 0;
    if (!(hasBCSocket || hasSockJS || hasWS)) {
      throw new Error('Must load socks or browserchannel before this library');
    }
    if (hasWS && !hasSockJS && !hasBCSocket) {
      useWS = true;
    }
    if (hasSockJS && !hasBCSocket(!hasWS)) {
      useSockJS = true;
    }
  } else {
    Connection = require('./connection').Connection;
  }
  exports.open = (function() {
    var connections, getConnection, maybeClose;
    connections = {};
    getConnection = function(origin, authentication) {
      var c, del, location, path;
      if (typeof WEB !== "undefined" && WEB !== null) {
        location = window.location;
        path = useSockJS ? 'sockjs' : 'channel';
                if (origin != null) {
          origin;
        } else {
          origin = "" + location.protocol + "//" + location.host + "/" + path;
        };
      }
      if (!connections[origin]) {
        c = new Connection(origin, authentication);
        del = function() {
          return delete connections[origin];
        };
        c.on('disconnected', del);
        c.on('connect failed', del);
        connections[origin] = c;
      }
      return connections[origin];
    };
    maybeClose = function(c) {
      var doc, name, numDocs, _ref;
      numDocs = 0;
      _ref = c.docs;
      for (name in _ref) {
        doc = _ref[name];
        if (doc.state !== 'closed' || doc.autoOpen) {
          numDocs++;
        }
      }
      if (numDocs === 0) {
        return c.disconnect();
      }
    };
    return function(docName, type, options, callback) {
      var authentication, c, origin;
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      if (typeof options === 'string') {
        options = {
          'origin': options
        };
      }
      origin = options.origin;
      authentication = options.authentication;
      c = getConnection(origin, authentication);
      c.numDocs++;
      c.open(docName, type, function(error, doc) {
        if (error) {
          callback(error);
          return maybeClose(c);
        } else {
          doc.on('closed', function() {
            return maybeClose(c);
          });
          return callback(null, doc);
        }
      });
      c.on('connect failed');
      return c;
    };
  })();
  if (typeof WEB === "undefined" || WEB === null) {
    exports.Doc = require('./doc').Doc;
    exports.Connection = require('./connection').Connection;
  }
}).call(this);
