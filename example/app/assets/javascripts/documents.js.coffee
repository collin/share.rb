class View
  tagName: "div"

  constructor: (@parent, @object) ->
    @element = document.createElement @tagName
    @parent.appendChild @element
    @render()

  on: (event, callback) ->
    $(@element).on event, callback

  appendChild: (child) ->
    @element.appendChild(child)

  remove: =>
    @parent?.removeChild(@element)

  parents: ->
    $(@element).parents()

class ObjectEditor extends View
  tagName: "dl"

  render: ->
    $(@element).addClass @object.constructor.name
    new PropertyCreator(this)
    for key, value of @object
      new ObjectKeyValueEditor(this, key, value)

class window.RootEditor extends ObjectEditor
  constructor: (parent, @document) ->
    super(parent, document.snapshot)
    console.log "BIND CHILD OP"
    @document.at().on('child op', @handleOperation)
    window.DOCUMENT = @document

  handleOperation: (path, operation) =>
    console.log "OPERATION", operation
    target = $("#document")
    if operation.oi? or operation.li?
      path = path[0..-2]
    console.log path
    for part in path
      if part.constructor is String
        target = target.find("[data-property=#{part}]:first")
      else if part.constructor is Number
        target = $ target.find("ol:first").children('li').get(part)

    if operation.li?
      parent = target.andSelf().find("ol:first")[0]
      new ArrayAtomEditor(parent, operation.li)

    if operation.ld?
      target.remove()

    if operation.oi?
      parent = target.find("dl:first")[0]
      new ObjectKeyValueEditor(parent, operation.p[path.length], operation.oi)

    if operation.od?
      console.log(target)
      target.remove()


class ObjectKeyValueEditor extends View
  tagName: "li"

  constructor: (@parent, @key, @value) ->
    super(@parent)

  render: ->
    $(@element).addClass(@value.constructor.name)
    $(@element).addClass("Property")
    $(@element).attr("data-property", @key)

    new ObjectKeyEditor(this, @key)
    new ObjectValueEditor(this, @value)

class ObjectKeyEditor extends View
  tagName: "dt"

  render: ->
    new ItemRemover(this)
    @key = document.createElement "span"
    @element.appendChild @key
    @key.setAttribute "contentEditable", true
    @key.innerHTML = @object

class ObjectValueEditor extends View
  tagName: "dd"
  render: ->
    if @object.constructor is Object
      new ObjectEditor(this, @object)
    else if @object.constructor is Array
      new ArrayEditor(this, @object)
    else
      new LiteralEditor(this, @object)

class ArrayEditor extends View
  tagName: "ol"

  render: ->
    new AtomCreator(this)
    for item in @object
      new ArrayAtomEditor(this, item)

class ArrayAtomEditor extends View
  tagName: "li"

  render: ->
    $(@element).addClass(@object.constructor.name)
    $(@element).addClass("Atom")
    new ItemRemover(this)
    if @object.constructor is Object
      new ObjectEditor(this, @object)
    else if @object.constructor is Array
      new ArrayEditor(this, @object)
    else
      new LiteralEditor(this, @object)

class Button extends View
  tagName: "button"
  buttonText: "Button"

  constructor: ->
    super
    @on "click", => @onclick()

  onclick: ->

  render: ->
    @element.setAttribute "class", @constructor.name
    @element.innerHTML = @buttonText

class Path
  constructor: (element) ->
    @element = $(element)

  parents: ->
    parents = []
    for el in @element.parents() 
      if $(el).attr('class')
        parents.push $(el)
    parents.reverse()

  toShare: ->
    parents = @parents()
    path = []
    console.log "toShare"
    for item in parents
      _class =  item.attr("class")
      console.log _class
      switch _class
        when "Object Property", "Array Property"
          path.push item.find("> dt span").text()
        when "Number Atom", "String Atom", "Array Atom", "Object Atom"
          path.push item.index() - 1
        when "Object"
          undefined
    console.log path
    return path


class ItemRemover extends Button
  buttonText: "-"
  onclick: ->
    path = new Path @element
    DOCUMENT.at(path.toShare()).remove()
    $(@element).andSelf().parents("li:first").remove()

class ItemCreator extends Button
  buttonText: "+"
  onclick: ->
    path = new Path @element
    new TypePicker document.body, (item) =>
      @created($(@element).parents("ol, dl")[0], path, item)

class PropertyCreator extends ItemCreator
  created: (parent, path, property) ->
    return unless key = prompt("What Property Key?")
    path = path.toShare()
    path.push key
    console.log "at", path, "set", property
    DOCUMENT.at(path).set(property)
    new ObjectKeyValueEditor(parent, key, property)

class AtomCreator extends ItemCreator
  created: (parent, path, atom) ->
    path = path.toShare()
    console.log parent, path, atom
    console.log "at", path, "set", atom
    DOCUMENT.at(path).push(atom)
    new ArrayAtomEditor(parent, atom)

class LiteralEditor extends View
  tagName: "span"

  render: ->
    @element.setAttribute "class", @object.constructor.name
    @element.setAttribute "contentEditable", true
    @element.innerHTML = @object

class TypePicker extends View
  tagName: "popup"
  constructor: (parent, createdCallback) ->
    @createdCallback = (item) =>
      @remove()
      createdCallback(item)
    super

  render: ->
    @appendChild @buttons = document.createElement "section"
    new ObjectCreator(@buttons, @createdCallback)
    new ArrayCreator(@buttons, @createdCallback)
    new NumberCreator(@buttons, @createdCallback)
    new StringCreator(@buttons, @createdCallback)
    new CloseButton(@buttons, @remove)

class CloseButton extends Button
  buttonText: "x"
  constructor: (parent, @onclick) ->
    super

class CreatorButton extends Button
  constructor: (parent, @createdCallback) -> super

  onclick: ->
    @createdCallback @create()

class ObjectCreator extends CreatorButton
  buttonText: "{} <u>O</u>bject"
  create: -> {}

class ArrayCreator extends CreatorButton
  buttonText: "[] <u>A</u>rray"
  create: -> []

class NumberCreator extends CreatorButton
  buttonText: "42 <u>N</u>umber"
  create: -> Number()

class StringCreator extends CreatorButton
  buttonText: "\"\" <u>S</u>tring"
  create: -> String()

