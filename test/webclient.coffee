# Tests for the client frontend.
client = sharejs
socket_url = "ws://localhost:3000/pads/share"
docName = "testingdoc"
client.open docName, 'text', socket_url, (error, doc) =>

types = sharejs.types

asyncTest 'open using the bare API', ->
  client.open docName, 'text', socket_url, (error, doc) =>
    console.log ":("
    ok doc
    #ifError error

    strictEqual doc.snapshot, ''
    strictEqual doc.name, docName
    strictEqual doc.type.name, types.text.name
    strictEqual doc.version, 0

    doc.close()
    start()

asyncTest 'open multiple documents using the bare API on the same connection', ->
  client.open docName, 'text', socket_url, (error, doc1) =>
    ok doc1
    #ifError error

    client.open docName + 2, 'text', socket_url, (error, doc2) ->
      ok doc2
      #ifError error

      doc2.submitOp {i:'hi'}, ->
        strictEqual doc2.snapshot, 'hi'
        doc1.submitOp {i:'booyah'}, ->
          strictEqual doc1.snapshot, 'booyah'
          doc2.close ->
            doc1.submitOp {i:'more text '}, ->
              strictEqual doc1.snapshot, 'more text booyah'

              doc1.close()
              doc2.close()
              start()

test 'create connection', ->
  ok @c

asyncTest 'create a new document', ->
  @c.open docName, 'text', (error, doc) =>
    ok doc
    #ifError error

    strictEqual doc.name, docName
    strictEqual doc.type.name, types.text.name
    strictEqual doc.version, 0
    start()

asyncTest 'open a document that is already open', ->
  @c.open docName, 'text', (error, doc1) =>
    #ifError error
    ok doc1
    strictEqual doc1.name, docName
    @c.open docName, 'text', (error, doc2) =>
      strictEqual doc1, doc2
      start()

asyncTest 'open a document that already exists', ->
  @model.create docName, 'text', =>
    @c.open docName, 'text', (error, doc) =>
      #ifError error
      ok doc

      strictEqual doc.type.name, 'text'
      strictEqual doc.version, 0
      start()

asyncTest 'open a document with a different type', ->
  @model.create docName, 'simple', =>
    @c.open docName, 'text', (error, doc) =>
      ok error
      equal doc, null
      start()

asyncTest 'submit an op to a document', ->
  @c.open docName, 'text', (error, doc) =>
    #ifError error
    strictEqual doc.name, docName

    doc.submitOp [{i:'hi', p:0}], =>
      deepEqual doc.snapshot, 'hi'
      strictEqual doc.version, 1
      start()

    # The document snapshot should be updated immediately.
    strictEqual doc.snapshot, 'hi'
    # ... but the version tracks the server version, so thats still 0.
    strictEqual doc.version, 0

asyncTest 'submit an op to a document using the API works', ->
  @c.open docName, 'text', (error, doc) =>
    doc.insert 0, 'hi', =>
      strictEqual doc.snapshot, 'hi'
      strictEqual doc.getText(), 'hi'
      @model.getSnapshot docName, (error, {snapshot}) ->
        strictEqual snapshot, 'hi'
        start()

asyncTest 'submitting an op while another op is inflight works', ->
  @c.open docName, 'text', (error, doc) =>
    #ifError error

    doc.submitOp [{i:'hi', p:0}], ->
      strictEqual doc.version, 1
    doc.flush()

    doc.submitOp [{i:'hi', p:2}], ->
      strictEqual doc.version, 2
      start()

asyncTest 'compose multiple ops together when they are submitted together', ->
  @c.open docName, 'text', (error, doc) =>
    #ifError error
    strictEqual doc.name, docName

    doc.submitOp [{i:'hi', p:0}], ->
      strictEqual doc.version, 1

    doc.submitOp [{i:'hi', p:0}], ->
      strictEqual doc.version, 1
      expect 4
      start()

asyncTest 'compose multiple ops together when they are submitted while an op is in flight', ->
  @c.open docName, 'text', (error, doc) =>
    #ifError error

    doc.submitOp [{i:'hi', p:0}], ->
      strictEqual doc.version, 1
    doc.flush()

    doc.submitOp [{i:'hi', p:2}], ->
      strictEqual doc.version, 2
    doc.submitOp [{i:'hi', p:4}], ->
      strictEqual doc.version, 2
      expect 4
      start()

asyncTest 'Receive submitted ops', ->
  @c.open docName, 'text', (error, doc) =>
    #ifError error
    strictEqual doc.name, docName

    doc.on 'remoteop', (op) ->
      deepEqual op, [{i:'hi', p:0}]

      expect 3
      start()

    @model.applyOp docName, {v:0, op:[{i:'hi', p:0}]}, (error, version) ->
      fail error if error

asyncTest 'get a nonexistent document passes null to the callback', ->
  @c.openExisting docName, (error, doc) ->
    strictEqual error, 'Document does not exist'
    equal doc, null
    start()

asyncTest 'get an existing document returns the document', ->
  @model.create docName, 'text', =>
    @c.openExisting docName, (error, doc) =>
      equal error, null
      ok doc

      strictEqual doc.name, docName
      strictEqual doc.type.name, 'text'
      strictEqual doc.version, 0
      start()

asyncTest 'client transforms remote ops before applying them', ->
  # There's a bit of magic in the timing of this  It would probably be more consistent
  # if this test were implemented using a stubbed out backend.

  clientOp = [{i:'client', p:0}]
  serverOp = [{i:'server', p:0}]
  serverTransformed = types.text.transform(serverOp, clientOp, 'right')

  finalDoc = types.text.create() # v1
  finalDoc = types.text.apply(finalDoc, clientOp) # v2
  finalDoc = types.text.apply(finalDoc, serverTransformed) #v3

  @c.open docName, 'text', (error, doc) =>
    opsRemaining = 2

    onOpApplied = ->
      opsRemaining--
      unless opsRemaining
        strictEqual doc.version, 2
        strictEqual doc.snapshot, finalDoc
        start()

    doc.submitOp clientOp, onOpApplied
    doc.on 'remoteop', (op) ->
      deepEqual op, serverTransformed
      onOpApplied()

    @model.applyOp docName, {v:0, op:serverOp}, (error) ->
      fail error if error

asyncTest 'doc fires both remoteop and change messages when remote ops are received', ->
  passPart = makePassPart test, 2
  @c.open docName, 'text', (error, doc) =>
    sentOp = [{i:'asdf', p:0}]
    doc.on 'change', (op) ->
      deepEqual op, sentOp
      passPart()
    doc.on 'remoteop', (op) ->
      deepEqual op, sentOp
      passPart()

    @model.applyOp docName, {v:0, op:sentOp}, (error) ->
      fail error if error

asyncTest 'doc only fires change ops from locally sent ops', ->
  passPart = makePassPart test, 2
  @c.open docName, 'text', (error, doc) ->
    sentOp = [{i:'asdf', p:0}]
    doc.on 'change', (op) ->
      deepEqual op, sentOp
      passPart()
    doc.on 'remoteop', (op) ->
      throw new Error 'Should not have received remoteOp event'

    doc.submitOp sentOp, (error, v) ->
      passPart()

asyncTest 'doc fires acknowledge event when it recieves acknowledgement from server', ->
  passPart = makePassPart test, 1
  @c.open docName, 'text', (error, doc) =>
    fail error if error
    sentOp = [{i:'asdf', p:0}]
    doc.on 'acknowledge', (op) ->
      deepEqual op, sentOp
      passPart()

    doc.submitOp sentOp

asyncTest 'doc does not receive ops after close called', ->
  @c.open docName, 'text', (error, doc) =>
    doc.on 'change', (op) ->
      throw new Error 'Should not have received op when the doc was unfollowed'

    doc.close =>
      @model.applyOp docName, {v:0, op:[{i:'asdf', p:0}]}, =>
        start()

asyncTest 'created locally is set on new docs', ->
  @c.open docName, 'text', (error, doc) =>
    strictEqual doc.created, true
    start()

asyncTest 'created locally is not set on old docs', ->
  @model.create docName, 'text', =>
    @c.open docName, 'text', (error, doc) =>
      strictEqual doc.created, false
      start()

asyncTest 'new Connection emits errors if auth rejects you', ->
  @auth = (client, action) -> action.reject()

  c = new client.Connection socket_url
  c.on 'connect', ->
    fail 'connection shouldnt have connected'
  c.on 'connect failed', (error) ->
    strictEqual error, 'forbidden'
    start()

asyncTest '(new Connection).open() fails if auth rejects the connection', ->
  @auth = (client, action) -> action.reject()

  passPart = makePassPart test, 2
  c = new client.Connection socket_url

  # Immediately opening a document should fail when the connection fails
  c.open docName, 'text', (error, doc) =>
    fail doc if doc
    strictEqual error, 'forbidden'
    passPart()

  c.on 'connect failed', =>
    # The connection is now in an invalid state. Lets try and open a document...
    c.open docName, 'text', (error, doc) =>
      fail doc if doc
      strictEqual error, 'connection closed'
      passPart()

asyncTest '(new Connection).open() fails if auth disallows reads', ->
  @auth = (client, action) ->
    if action.type == 'read' then action.reject() else action.accept()

  c = new client.Connection socket_url
  c.open docName, 'text', (error, doc) =>
    fail doc if doc
    strictEqual error, 'forbidden'
    c.disconnect()
    start()

asyncTest 'client.open fails if auth rejects the connection', ->
  @auth = (client, action) -> action.reject()

  client.open docName, 'text', socket_url, (error, doc) =>
    fail doc if doc
    strictEqual error, 'forbidden'
    start()

asyncTest 'client.open fails if auth disallows reads', ->
  @auth = (client, action) ->
    if action.type == 'read' then action.reject() else action.accept()

  client.open docName, 'text', socket_url, (error, doc) =>
    fail doc if doc
    strictEqual error, 'forbidden'
    start()

asyncTest "Can't submit an op if auth rejects you", ->
  @auth = (client, action) ->
    if action.name == 'submit op' then action.reject() else action.accept()

  @c.open docName, 'text', (error, doc) =>
    doc.insert 0, 'hi', (error, op) =>
      strictEqual error, 'forbidden'
      strictEqual doc.getText(), ''
      # Also need to test that ops sent afterwards get sent correctly.
      # because that behaviour IS CURRENTLY BROKEN

      @model.getSnapshot docName, (error, {snapshot}) ->
        strictEqual snapshot, ''
        start()

asyncTest 'If an operation is rejected, the undo is applied as if auth did it', ->
  @auth = (client, action) ->
    if action.name == 'submit op' then action.reject() else action.accept()

  @c.open docName, 'text', (error, doc) =>
    doc.on 'delete', (pos, text) ->
      strictEqual text, 'hi'
      strictEqual pos, 0
      start()

    doc.insert 0, 'hi'

asyncTest 'error message passed to reject is the error passed to client', ->
  @auth = (client, action) -> action.reject('not allowed')

  client.open docName, 'text', socket_url, (error, doc) =>
    strictEqual error, 'not allowed'
    start()

asyncTest 'If auth rejects your op, other transforms work correctly', ->
  # This should probably have a randomized tester as well.
  @auth = (client, action) ->
    if action.name == 'submit op' and action.op[0].d == 'cC'
      action.reject()
    else
      action.accept()

  @c.open docName, 'text', (error, doc) =>
    doc.insert 0, 'abcCBA', =>
      e = expectCalls 3, =>
        # The b's are successfully deleted, the ds are added by the server and the
        # op to delete the cs is denied.
        @model.getSnapshot docName, (error, {snapshot}) ->
          deepEqual snapshot, 'acdDCA'
          start()

      doc.del 2, 2, (error, op) => # Delete the 'cC', so the document becomes 'abBA'
        # This op is denied by the auth code
        strictEqual error, 'forbidden'
        e()

      strictEqual doc.getText(), 'abBA'
      doc.flush()

      # Simultaneously, we'll apply another op locally:
      doc.del 1, 2, -> # Delete the 'bB'
        e()
      strictEqual doc.getText(), 'aA'

      # ... and yet another op on the server. (Remember, the server hasn't seen either op yet.)
      @model.applyOp docName, {op:[{i:'dD', p:3}], v:1, meta:{}}, =>
        @model.getSnapshot docName, e

asyncTest 'If operation is rejected, action.responded == true', ->
  @auth = (client, action) ->
    strictEqual action.responded, false
    action.reject()
    strictEqual action.responded, true
    start()

  client.open docName, 'text', socket_url, (error, doc) =>

asyncTest 'If operation is accepted, action.responded == true', ->
  @auth = (client, action) ->
    strictEqual action.responded, false
    action.accept()
    strictEqual action.responded, true
    start()

  client.open docName, 'text', socket_url, (error, doc) =>

asyncTest 'Text API is advertised', ->
  @c.open docName, 'text', (error, doc) ->
    strictEqual doc.provides?.text, true
    doc.close()
    start()

asyncTest 'Text API can be used to insert into the document', ->
  @c.open docName, 'text', (error, doc) =>
    doc.insert 0, 'hi', =>
      strictEqual doc.getText(), 'hi'

      @model.getSnapshot docName, (error, data) ->
        strictEqual data.snapshot, 'hi'
        doc.close()
        start()

asyncTest 'Text documents emit high level editing events', ->
  @c.open docName, 'text', (error, doc) =>
    doc.on 'insert', (pos, text) ->
      strictEqual text, 'hi'
      strictEqual pos, 0
      doc.close()
      start()

    @model.applyOp docName, {op:[{i:'hi', p:0}], v:0, meta:{}}

asyncTest 'Works with an externally referenced type (like JSON)', ->
  @c.open docName, 'json', (error, doc) ->
    #ifError error
    strictEqual doc.snapshot, null
    doc.submitOp [{p:[], od:null, oi:[1,2,3]}], ->
      deepEqual doc.snapshot, [1,2,3]
      doc.close()
      start()

asyncTest '.open() throws an exception if the type is missing', ->
  throws ->
    @c.open docName, 'does not exist', ->
  start()

asyncTest 'Submitting an op and closing straight after works', ->
  # This catches a real bug.
  client.open docName, 'text', socket_url, (error, doc) =>
    doc.insert 0, 'hi'
    doc.close ->
      start()

asyncTest 'Can open a document after closing a document', ->
  port = @port
  name = docName
  client.open name, 'text', "http://localhost:#{port}/sjs", (error, doc1) =>
    #ifError error
    ok doc1
    doc1.close ->
      client.open name + '1', 'text', "http://localhost:#{port}/sjs", (error, doc2) ->
        #ifError error
        ok doc2
        doc2.close ->
          start()
