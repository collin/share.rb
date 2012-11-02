(function() {
  var client, docName, socket_url, types,
    _this = this;

  client = sharejs;

  socket_url = "ws://localhost:3000/pads/share";

  docName = "testingdoc";

  client.open(docName, 'text', socket_url, function(error, doc) {});

  types = sharejs.types;

  asyncTest('open using the bare API', function() {
    var _this = this;
    return client.open(docName, 'text', socket_url, function(error, doc) {
      console.log(":(");
      ok(doc);
      strictEqual(doc.snapshot, '');
      strictEqual(doc.name, docName);
      strictEqual(doc.type.name, types.text.name);
      strictEqual(doc.version, 0);
      doc.close();
      return start();
    });
  });

  asyncTest('open multiple documents using the bare API on the same connection', function() {
    var _this = this;
    return client.open(docName, 'text', socket_url, function(error, doc1) {
      ok(doc1);
      return client.open(docName + 2, 'text', socket_url, function(error, doc2) {
        ok(doc2);
        return doc2.submitOp({
          i: 'hi'
        }, function() {
          strictEqual(doc2.snapshot, 'hi');
          return doc1.submitOp({
            i: 'booyah'
          }, function() {
            strictEqual(doc1.snapshot, 'booyah');
            return doc2.close(function() {
              return doc1.submitOp({
                i: 'more text '
              }, function() {
                strictEqual(doc1.snapshot, 'more text booyah');
                doc1.close();
                doc2.close();
                return start();
              });
            });
          });
        });
      });
    });
  });

  test('create connection', function() {
    return ok(this.c);
  });

  asyncTest('create a new document', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      ok(doc);
      strictEqual(doc.name, docName);
      strictEqual(doc.type.name, types.text.name);
      strictEqual(doc.version, 0);
      return start();
    });
  });

  asyncTest('open a document that is already open', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc1) {
      ok(doc1);
      strictEqual(doc1.name, docName);
      return _this.c.open(docName, 'text', function(error, doc2) {
        strictEqual(doc1, doc2);
        return start();
      });
    });
  });

  asyncTest('open a document that already exists', function() {
    var _this = this;
    return this.model.create(docName, 'text', function() {
      return _this.c.open(docName, 'text', function(error, doc) {
        ok(doc);
        strictEqual(doc.type.name, 'text');
        strictEqual(doc.version, 0);
        return start();
      });
    });
  });

  asyncTest('open a document with a different type', function() {
    var _this = this;
    return this.model.create(docName, 'simple', function() {
      return _this.c.open(docName, 'text', function(error, doc) {
        ok(error);
        equal(doc, null);
        return start();
      });
    });
  });

  asyncTest('submit an op to a document', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      strictEqual(doc.name, docName);
      doc.submitOp([
        {
          i: 'hi',
          p: 0
        }
      ], function() {
        deepEqual(doc.snapshot, 'hi');
        strictEqual(doc.version, 1);
        return start();
      });
      strictEqual(doc.snapshot, 'hi');
      return strictEqual(doc.version, 0);
    });
  });

  asyncTest('submit an op to a document using the API works', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      return doc.insert(0, 'hi', function() {
        strictEqual(doc.snapshot, 'hi');
        strictEqual(doc.getText(), 'hi');
        return _this.model.getSnapshot(docName, function(error, _arg) {
          var snapshot;
          snapshot = _arg.snapshot;
          strictEqual(snapshot, 'hi');
          return start();
        });
      });
    });
  });

  asyncTest('submitting an op while another op is inflight works', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      doc.submitOp([
        {
          i: 'hi',
          p: 0
        }
      ], function() {
        return strictEqual(doc.version, 1);
      });
      doc.flush();
      return doc.submitOp([
        {
          i: 'hi',
          p: 2
        }
      ], function() {
        strictEqual(doc.version, 2);
        return start();
      });
    });
  });

  asyncTest('compose multiple ops together when they are submitted together', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      strictEqual(doc.name, docName);
      doc.submitOp([
        {
          i: 'hi',
          p: 0
        }
      ], function() {
        return strictEqual(doc.version, 1);
      });
      return doc.submitOp([
        {
          i: 'hi',
          p: 0
        }
      ], function() {
        strictEqual(doc.version, 1);
        expect(4);
        return start();
      });
    });
  });

  asyncTest('compose multiple ops together when they are submitted while an op is in flight', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      doc.submitOp([
        {
          i: 'hi',
          p: 0
        }
      ], function() {
        return strictEqual(doc.version, 1);
      });
      doc.flush();
      doc.submitOp([
        {
          i: 'hi',
          p: 2
        }
      ], function() {
        return strictEqual(doc.version, 2);
      });
      return doc.submitOp([
        {
          i: 'hi',
          p: 4
        }
      ], function() {
        strictEqual(doc.version, 2);
        expect(4);
        return start();
      });
    });
  });

  asyncTest('Receive submitted ops', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      strictEqual(doc.name, docName);
      doc.on('remoteop', function(op) {
        deepEqual(op, [
          {
            i: 'hi',
            p: 0
          }
        ]);
        expect(3);
        return start();
      });
      return _this.model.applyOp(docName, {
        v: 0,
        op: [
          {
            i: 'hi',
            p: 0
          }
        ]
      }, function(error, version) {
        if (error) return fail(error);
      });
    });
  });

  asyncTest('get a nonexistent document passes null to the callback', function() {
    return this.c.openExisting(docName, function(error, doc) {
      strictEqual(error, 'Document does not exist');
      equal(doc, null);
      return start();
    });
  });

  asyncTest('get an existing document returns the document', function() {
    var _this = this;
    return this.model.create(docName, 'text', function() {
      return _this.c.openExisting(docName, function(error, doc) {
        equal(error, null);
        ok(doc);
        strictEqual(doc.name, docName);
        strictEqual(doc.type.name, 'text');
        strictEqual(doc.version, 0);
        return start();
      });
    });
  });

  asyncTest('client transforms remote ops before applying them', function() {
    var clientOp, finalDoc, serverOp, serverTransformed,
      _this = this;
    clientOp = [
      {
        i: 'client',
        p: 0
      }
    ];
    serverOp = [
      {
        i: 'server',
        p: 0
      }
    ];
    serverTransformed = types.text.transform(serverOp, clientOp, 'right');
    finalDoc = types.text.create();
    finalDoc = types.text.apply(finalDoc, clientOp);
    finalDoc = types.text.apply(finalDoc, serverTransformed);
    return this.c.open(docName, 'text', function(error, doc) {
      var onOpApplied, opsRemaining;
      opsRemaining = 2;
      onOpApplied = function() {
        opsRemaining--;
        if (!opsRemaining) {
          strictEqual(doc.version, 2);
          strictEqual(doc.snapshot, finalDoc);
          return start();
        }
      };
      doc.submitOp(clientOp, onOpApplied);
      doc.on('remoteop', function(op) {
        deepEqual(op, serverTransformed);
        return onOpApplied();
      });
      return _this.model.applyOp(docName, {
        v: 0,
        op: serverOp
      }, function(error) {
        if (error) return fail(error);
      });
    });
  });

  asyncTest('doc fires both remoteop and change messages when remote ops are received', function() {
    var passPart,
      _this = this;
    passPart = makePassPart(test, 2);
    return this.c.open(docName, 'text', function(error, doc) {
      var sentOp;
      sentOp = [
        {
          i: 'asdf',
          p: 0
        }
      ];
      doc.on('change', function(op) {
        deepEqual(op, sentOp);
        return passPart();
      });
      doc.on('remoteop', function(op) {
        deepEqual(op, sentOp);
        return passPart();
      });
      return _this.model.applyOp(docName, {
        v: 0,
        op: sentOp
      }, function(error) {
        if (error) return fail(error);
      });
    });
  });

  asyncTest('doc only fires change ops from locally sent ops', function() {
    var passPart;
    passPart = makePassPart(test, 2);
    return this.c.open(docName, 'text', function(error, doc) {
      var sentOp;
      sentOp = [
        {
          i: 'asdf',
          p: 0
        }
      ];
      doc.on('change', function(op) {
        deepEqual(op, sentOp);
        return passPart();
      });
      doc.on('remoteop', function(op) {
        throw new Error('Should not have received remoteOp event');
      });
      return doc.submitOp(sentOp, function(error, v) {
        return passPart();
      });
    });
  });

  asyncTest('doc fires acknowledge event when it recieves acknowledgement from server', function() {
    var passPart,
      _this = this;
    passPart = makePassPart(test, 1);
    return this.c.open(docName, 'text', function(error, doc) {
      var sentOp;
      if (error) fail(error);
      sentOp = [
        {
          i: 'asdf',
          p: 0
        }
      ];
      doc.on('acknowledge', function(op) {
        deepEqual(op, sentOp);
        return passPart();
      });
      return doc.submitOp(sentOp);
    });
  });

  asyncTest('doc does not receive ops after close called', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      doc.on('change', function(op) {
        throw new Error('Should not have received op when the doc was unfollowed');
      });
      return doc.close(function() {
        return _this.model.applyOp(docName, {
          v: 0,
          op: [
            {
              i: 'asdf',
              p: 0
            }
          ]
        }, function() {
          return start();
        });
      });
    });
  });

  asyncTest('created locally is set on new docs', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      strictEqual(doc.created, true);
      return start();
    });
  });

  asyncTest('created locally is not set on old docs', function() {
    var _this = this;
    return this.model.create(docName, 'text', function() {
      return _this.c.open(docName, 'text', function(error, doc) {
        strictEqual(doc.created, false);
        return start();
      });
    });
  });

  asyncTest('new Connection emits errors if auth rejects you', function() {
    var c;
    this.auth = function(client, action) {
      return action.reject();
    };
    c = new client.Connection(socket_url);
    c.on('connect', function() {
      return fail('connection shouldnt have connected');
    });
    return c.on('connect failed', function(error) {
      strictEqual(error, 'forbidden');
      return start();
    });
  });

  asyncTest('(new Connection).open() fails if auth rejects the connection', function() {
    var c, passPart,
      _this = this;
    this.auth = function(client, action) {
      return action.reject();
    };
    passPart = makePassPart(test, 2);
    c = new client.Connection(socket_url);
    c.open(docName, 'text', function(error, doc) {
      if (doc) fail(doc);
      strictEqual(error, 'forbidden');
      return passPart();
    });
    return c.on('connect failed', function() {
      return c.open(docName, 'text', function(error, doc) {
        if (doc) fail(doc);
        strictEqual(error, 'connection closed');
        return passPart();
      });
    });
  });

  asyncTest('(new Connection).open() fails if auth disallows reads', function() {
    var c,
      _this = this;
    this.auth = function(client, action) {
      if (action.type === 'read') {
        return action.reject();
      } else {
        return action.accept();
      }
    };
    c = new client.Connection(socket_url);
    return c.open(docName, 'text', function(error, doc) {
      if (doc) fail(doc);
      strictEqual(error, 'forbidden');
      c.disconnect();
      return start();
    });
  });

  asyncTest('client.open fails if auth rejects the connection', function() {
    var _this = this;
    this.auth = function(client, action) {
      return action.reject();
    };
    return client.open(docName, 'text', socket_url, function(error, doc) {
      if (doc) fail(doc);
      strictEqual(error, 'forbidden');
      return start();
    });
  });

  asyncTest('client.open fails if auth disallows reads', function() {
    var _this = this;
    this.auth = function(client, action) {
      if (action.type === 'read') {
        return action.reject();
      } else {
        return action.accept();
      }
    };
    return client.open(docName, 'text', socket_url, function(error, doc) {
      if (doc) fail(doc);
      strictEqual(error, 'forbidden');
      return start();
    });
  });

  asyncTest("Can't submit an op if auth rejects you", function() {
    var _this = this;
    this.auth = function(client, action) {
      if (action.name === 'submit op') {
        return action.reject();
      } else {
        return action.accept();
      }
    };
    return this.c.open(docName, 'text', function(error, doc) {
      return doc.insert(0, 'hi', function(error, op) {
        strictEqual(error, 'forbidden');
        strictEqual(doc.getText(), '');
        return _this.model.getSnapshot(docName, function(error, _arg) {
          var snapshot;
          snapshot = _arg.snapshot;
          strictEqual(snapshot, '');
          return start();
        });
      });
    });
  });

  asyncTest('If an operation is rejected, the undo is applied as if auth did it', function() {
    var _this = this;
    this.auth = function(client, action) {
      if (action.name === 'submit op') {
        return action.reject();
      } else {
        return action.accept();
      }
    };
    return this.c.open(docName, 'text', function(error, doc) {
      doc.on('delete', function(pos, text) {
        strictEqual(text, 'hi');
        strictEqual(pos, 0);
        return start();
      });
      return doc.insert(0, 'hi');
    });
  });

  asyncTest('error message passed to reject is the error passed to client', function() {
    var _this = this;
    this.auth = function(client, action) {
      return action.reject('not allowed');
    };
    return client.open(docName, 'text', socket_url, function(error, doc) {
      strictEqual(error, 'not allowed');
      return start();
    });
  });

  asyncTest('If auth rejects your op, other transforms work correctly', function() {
    var _this = this;
    this.auth = function(client, action) {
      if (action.name === 'submit op' && action.op[0].d === 'cC') {
        return action.reject();
      } else {
        return action.accept();
      }
    };
    return this.c.open(docName, 'text', function(error, doc) {
      return doc.insert(0, 'abcCBA', function() {
        var e;
        e = expectCalls(3, function() {
          return _this.model.getSnapshot(docName, function(error, _arg) {
            var snapshot;
            snapshot = _arg.snapshot;
            deepEqual(snapshot, 'acdDCA');
            return start();
          });
        });
        doc.del(2, 2, function(error, op) {
          strictEqual(error, 'forbidden');
          return e();
        });
        strictEqual(doc.getText(), 'abBA');
        doc.flush();
        doc.del(1, 2, function() {
          return e();
        });
        strictEqual(doc.getText(), 'aA');
        return _this.model.applyOp(docName, {
          op: [
            {
              i: 'dD',
              p: 3
            }
          ],
          v: 1,
          meta: {}
        }, function() {
          return _this.model.getSnapshot(docName, e);
        });
      });
    });
  });

  asyncTest('If operation is rejected, action.responded == true', function() {
    var _this = this;
    this.auth = function(client, action) {
      strictEqual(action.responded, false);
      action.reject();
      strictEqual(action.responded, true);
      return start();
    };
    return client.open(docName, 'text', socket_url, function(error, doc) {});
  });

  asyncTest('If operation is accepted, action.responded == true', function() {
    var _this = this;
    this.auth = function(client, action) {
      strictEqual(action.responded, false);
      action.accept();
      strictEqual(action.responded, true);
      return start();
    };
    return client.open(docName, 'text', socket_url, function(error, doc) {});
  });

  asyncTest('Text API is advertised', function() {
    return this.c.open(docName, 'text', function(error, doc) {
      var _ref;
      strictEqual((_ref = doc.provides) != null ? _ref.text : void 0, true);
      doc.close();
      return start();
    });
  });

  asyncTest('Text API can be used to insert into the document', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      return doc.insert(0, 'hi', function() {
        strictEqual(doc.getText(), 'hi');
        return _this.model.getSnapshot(docName, function(error, data) {
          strictEqual(data.snapshot, 'hi');
          doc.close();
          return start();
        });
      });
    });
  });

  asyncTest('Text documents emit high level editing events', function() {
    var _this = this;
    return this.c.open(docName, 'text', function(error, doc) {
      doc.on('insert', function(pos, text) {
        strictEqual(text, 'hi');
        strictEqual(pos, 0);
        doc.close();
        return start();
      });
      return _this.model.applyOp(docName, {
        op: [
          {
            i: 'hi',
            p: 0
          }
        ],
        v: 0,
        meta: {}
      });
    });
  });

  asyncTest('Works with an externally referenced type (like JSON)', function() {
    return this.c.open(docName, 'json', function(error, doc) {
      strictEqual(doc.snapshot, null);
      return doc.submitOp([
        {
          p: [],
          od: null,
          oi: [1, 2, 3]
        }
      ], function() {
        deepEqual(doc.snapshot, [1, 2, 3]);
        doc.close();
        return start();
      });
    });
  });

  asyncTest('.open() throws an exception if the type is missing', function() {
    throws(function() {
      return this.c.open(docName, 'does not exist', function() {});
    });
    return start();
  });

  asyncTest('Submitting an op and closing straight after works', function() {
    var _this = this;
    return client.open(docName, 'text', socket_url, function(error, doc) {
      doc.insert(0, 'hi');
      return doc.close(function() {
        return start();
      });
    });
  });

  asyncTest('Can open a document after closing a document', function() {
    var name, port,
      _this = this;
    port = this.port;
    name = docName;
    return client.open(name, 'text', "http://localhost:" + port + "/sjs", function(error, doc1) {
      ok(doc1);
      return doc1.close(function() {
        return client.open(name + '1', 'text', "http://localhost:" + port + "/sjs", function(error, doc2) {
          ok(doc2);
          return doc2.close(function() {
            return start();
          });
        });
      });
    });
  });

}).call(this);
