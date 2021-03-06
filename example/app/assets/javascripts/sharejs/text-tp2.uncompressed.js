(function() {
  /**
   @const
   @type {boolean}
*/
var WEB = true;
;  var append, appendDoc, appendSkipChars, checkOp, componentLength, exports, makeTake, takeDoc, transformer, type;
  exports = window['sharejs'];
  type = {
    name: 'text-tp2',
    tp2: true,
    create: function() {
      return {
        charLength: 0,
        totalLength: 0,
        positionCache: [],
        data: []
      };
    },
    serialize: function(doc) {
      if (!doc.data) {
        throw new Error('invalid doc snapshot');
      }
      return doc.data;
    },
    deserialize: function(data) {
      var component, doc, _i, _len;
      doc = type.create();
      doc.data = data;
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        component = data[_i];
        if (typeof component === 'string') {
          doc.charLength += component.length;
          doc.totalLength += component.length;
        } else {
          doc.totalLength += component;
        }
      }
      return doc;
    }
  };
  checkOp = function(op) {
    var c, last, _i, _len, _results;
    if (!Array.isArray(op)) {
      throw new Error('Op must be an array of components');
    }
    last = null;
    _results = [];
    for (_i = 0, _len = op.length; _i < _len; _i++) {
      c = op[_i];
      if (typeof c === 'object') {
        if (c.i !== void 0) {
          if (!((typeof c.i === 'string' && c.i.length > 0) || (typeof c.i === 'number' && c.i > 0))) {
            throw new Error('Inserts must insert a string or a +ive number');
          }
        } else if (c.d !== void 0) {
          if (!(typeof c.d === 'number' && c.d > 0)) {
            throw new Error('Deletes must be a +ive number');
          }
        } else {
          throw new Error('Operation component must define .i or .d');
        }
      } else {
        if (typeof c !== 'number') {
          throw new Error('Op components must be objects or numbers');
        }
        if (!(c > 0)) {
          throw new Error('Skip components must be a positive number');
        }
        if (typeof last === 'number') {
          throw new Error('Adjacent skip components should be combined');
        }
      }
      _results.push(last = c);
    }
    return _results;
  };
  type._takeDoc = takeDoc = function(doc, position, maxlength, tombsIndivisible) {
    var part, result, resultLen;
    if (position.index >= doc.data.length) {
      throw new Error('Operation goes past the end of the document');
    }
    part = doc.data[position.index];
    result = typeof part === 'string' ? maxlength !== void 0 ? part.slice(position.offset, position.offset + maxlength) : part.slice(position.offset) : maxlength === void 0 || tombsIndivisible ? part - position.offset : Math.min(maxlength, part - position.offset);
    resultLen = result.length || result;
    if ((part.length || part) - position.offset > resultLen) {
      position.offset += resultLen;
    } else {
      position.index++;
      position.offset = 0;
    }
    return result;
  };
  type._appendDoc = appendDoc = function(doc, p) {
    var data;
    if (p === 0 || p === '') {
      return;
    }
    if (typeof p === 'string') {
      doc.charLength += p.length;
      doc.totalLength += p.length;
    } else {
      doc.totalLength += p;
    }
    data = doc.data;
    if (data.length === 0) {
      data.push(p);
    } else if (typeof data[data.length - 1] === typeof p) {
      data[data.length - 1] += p;
    } else {
      data.push(p);
    }
  };
  type.apply = function(doc, op) {
    var component, newDoc, part, position, remainder, _i, _len;
    if (!(doc.totalLength !== void 0 && doc.charLength !== void 0 && doc.data.length !== void 0)) {
      throw new Error('Snapshot is invalid');
    }
    checkOp(op);
    newDoc = type.create();
    position = {
      index: 0,
      offset: 0
    };
    for (_i = 0, _len = op.length; _i < _len; _i++) {
      component = op[_i];
      if (typeof component === 'number') {
        remainder = component;
        while (remainder > 0) {
          part = takeDoc(doc, position, remainder);
          appendDoc(newDoc, part);
          remainder -= part.length || part;
        }
      } else if (component.i !== void 0) {
        appendDoc(newDoc, component.i);
      } else if (component.d !== void 0) {
        remainder = component.d;
        while (remainder > 0) {
          part = takeDoc(doc, position, remainder);
          remainder -= part.length || part;
        }
        appendDoc(newDoc, component.d);
      }
    }
    return newDoc;
  };
  type._append = append = function(op, component) {
    var last;
    if (component === 0 || component.i === '' || component.i === 0 || component.d === 0) {
      ;
    } else if (op.length === 0) {
      return op.push(component);
    } else {
      last = op[op.length - 1];
      if (typeof component === 'number' && typeof last === 'number') {
        return op[op.length - 1] += component;
      } else if (component.i !== void 0 && (last.i != null) && typeof last.i === typeof component.i) {
        return last.i += component.i;
      } else if (component.d !== void 0 && (last.d != null)) {
        return last.d += component.d;
      } else {
        return op.push(component);
      }
    }
  };
  makeTake = function(op) {
    var index, offset, peekType, take;
    index = 0;
    offset = 0;
    take = function(maxlength, insertsIndivisible) {
      var c, current, e, result;
      if (index === op.length) {
        return null;
      }
      e = op[index];
      if (typeof (current = e) === 'number' || typeof (current = e.i) === 'number' || (current = e.d) !== void 0) {
        if (!(maxlength != null) || current - offset <= maxlength || (insertsIndivisible && e.i !== void 0)) {
          c = current - offset;
          ++index;
          offset = 0;
        } else {
          offset += maxlength;
          c = maxlength;
        }
        if (e.i !== void 0) {
          return {
            i: c
          };
        } else if (e.d !== void 0) {
          return {
            d: c
          };
        } else {
          return c;
        }
      } else {
        if (!(maxlength != null) || e.i.length - offset <= maxlength || insertsIndivisible) {
          result = {
            i: e.i.slice(offset)
          };
          ++index;
          offset = 0;
        } else {
          result = {
            i: e.i.slice(offset, offset + maxlength)
          };
          offset += maxlength;
        }
        return result;
      }
    };
    peekType = function() {
      return op[index];
    };
    return [take, peekType];
  };
  componentLength = function(component) {
    if (typeof component === 'number') {
      return component;
    } else if (typeof component.i === 'string') {
      return component.i.length;
    } else {
      return component.d || component.i;
    }
  };
  type.normalize = function(op) {
    var component, newOp, _i, _len;
    newOp = [];
    for (_i = 0, _len = op.length; _i < _len; _i++) {
      component = op[_i];
      append(newOp, component);
    }
    return newOp;
  };
  transformer = function(op, otherOp, goForwards, side) {
    var chunk, component, length, newOp, peek, take, _i, _len, _ref, _ref2;
    checkOp(op);
    checkOp(otherOp);
    newOp = [];
    _ref = makeTake(op), take = _ref[0], peek = _ref[1];
    for (_i = 0, _len = otherOp.length; _i < _len; _i++) {
      component = otherOp[_i];
      length = componentLength(component);
      if (component.i !== void 0) {
        if (goForwards) {
          if (side === 'left') {
            while (((_ref2 = peek()) != null ? _ref2.i : void 0) !== void 0) {
              append(newOp, take());
            }
          }
          append(newOp, length);
        } else {
          while (length > 0) {
            chunk = take(length, true);
            if (chunk === null) {
              throw new Error('The transformed op is invalid');
            }
            if (chunk.d !== void 0) {
              throw new Error('The transformed op deletes locally inserted characters - it cannot be purged of the insert.');
            }
            if (typeof chunk === 'number') {
              length -= chunk;
            } else {
              append(newOp, chunk);
            }
          }
        }
      } else {
        while (length > 0) {
          chunk = take(length, true);
          if (chunk === null) {
            throw new Error('The op traverses more elements than the document has');
          }
          append(newOp, chunk);
          if (!chunk.i) {
            length -= componentLength(chunk);
          }
        }
      }
    }
    while ((component = take())) {
      if (component.i === void 0) {
        throw new Error("Remaining fragments in the op: " + component);
      }
      append(newOp, component);
    }
    return newOp;
  };
  type.transform = function(op, otherOp, side) {
    if (!(side === 'left' || side === 'right')) {
      throw new Error("side (" + side + ") should be 'left' or 'right'");
    }
    return transformer(op, otherOp, true, side);
  };
  type.prune = function(op, otherOp) {
    return transformer(op, otherOp, false);
  };
  type.compose = function(op1, op2) {
    var chunk, chunkLength, component, length, result, take, _, _i, _len, _ref;
    if (op1 === null || op1 === void 0) {
      return op2;
    }
    checkOp(op1);
    checkOp(op2);
    result = [];
    _ref = makeTake(op1), take = _ref[0], _ = _ref[1];
    for (_i = 0, _len = op2.length; _i < _len; _i++) {
      component = op2[_i];
      if (typeof component === 'number') {
        length = component;
        while (length > 0) {
          chunk = take(length);
          if (chunk === null) {
            throw new Error('The op traverses more elements than the document has');
          }
          append(result, chunk);
          length -= componentLength(chunk);
        }
      } else if (component.i !== void 0) {
        append(result, {
          i: component.i
        });
      } else {
        length = component.d;
        while (length > 0) {
          chunk = take(length);
          if (chunk === null) {
            throw new Error('The op traverses more elements than the document has');
          }
          chunkLength = componentLength(chunk);
          if (chunk.i !== void 0) {
            append(result, {
              i: chunkLength
            });
          } else {
            append(result, {
              d: chunkLength
            });
          }
          length -= chunkLength;
        }
      }
    }
    while ((component = take())) {
      if (component.i === void 0) {
        throw new Error("Remaining fragments in op1: " + component);
      }
      append(result, component);
    }
    return result;
  };
  if (typeof WEB !== "undefined" && WEB !== null) {
    exports.types['text-tp2'] = type;
  } else {
    module.exports = type;
  }
  if (typeof WEB !== "undefined" && WEB !== null) {
    type = exports.types['text-tp2'];
  } else {
    type = require('./text-tp2');
  }
  takeDoc = type._takeDoc, append = type._append;
  appendSkipChars = function(op, doc, pos, maxlength) {
    var part, _results;
    _results = [];
    while ((maxlength === void 0 || maxlength > 0) && pos.index < doc.data.length) {
      part = takeDoc(doc, pos, maxlength, true);
      if (maxlength !== void 0 && typeof part === 'string') {
        maxlength -= part.length;
      }
      _results.push(append(op, part.length || part));
    }
    return _results;
  };
  type['api'] = {
    'provides': {
      'text': true
    },
    'getLength': function() {
      return this.snapshot.charLength;
    },
    'getText': function() {
      var elem, strings;
      strings = (function() {
        var _i, _len, _ref, _results;
        _ref = this.snapshot.data;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          elem = _ref[_i];
          if (typeof elem === 'string') {
            _results.push(elem);
          }
        }
        return _results;
      }).call(this);
      return strings.join('');
    },
    'insert': function(pos, text, callback) {
      var docPos, op;
      if (pos === void 0) {
        pos = 0;
      }
      op = [];
      docPos = {
        index: 0,
        offset: 0
      };
      appendSkipChars(op, this.snapshot, docPos, pos);
      append(op, {
        'i': text
      });
      appendSkipChars(op, this.snapshot, docPos);
      this.submitOp(op, callback);
      return op;
    },
    'del': function(pos, length, callback) {
      var docPos, op, part;
      op = [];
      docPos = {
        index: 0,
        offset: 0
      };
      appendSkipChars(op, this.snapshot, docPos, pos);
      while (length > 0) {
        part = takeDoc(this.snapshot, docPos, length, true);
        if (typeof part === 'string') {
          append(op, {
            'd': part.length
          });
          length -= part.length;
        } else {
          append(op, part);
        }
      }
      appendSkipChars(op, this.snapshot, docPos);
      this.submitOp(op, callback);
      return op;
    },
    '_register': function() {
      return this.on('remoteop', function(op, snapshot) {
        var component, docPos, part, remainder, textPos, _i, _len;
        textPos = 0;
        docPos = {
          index: 0,
          offset: 0
        };
        for (_i = 0, _len = op.length; _i < _len; _i++) {
          component = op[_i];
          if (typeof component === 'number') {
            remainder = component;
            while (remainder > 0) {
              part = takeDoc(snapshot, docPos, remainder);
              if (typeof part === 'string') {
                textPos += part.length;
              }
              remainder -= part.length || part;
            }
          } else if (component.i !== void 0) {
            if (typeof component.i === 'string') {
              this.emit('insert', textPos, component.i);
              textPos += component.i.length;
            }
          } else {
            remainder = component.d;
            while (remainder > 0) {
              part = takeDoc(snapshot, docPos, remainder);
              if (typeof part === 'string') {
                this.emit('delete', textPos, part);
              }
              remainder -= part.length || part;
            }
          }
        }
      });
    }
  };
}).call(this);
