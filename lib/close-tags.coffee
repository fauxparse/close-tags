module.exports =
  emptyTags: []

  config:
    emptyTags:
      type: "array"
      default: [
        "br", "hr", "img", "input", "link", "meta", "area", "base", "col",
        "command", "embed", "keygen", "param", "source", "track", "wbr"
      ]
      items:
        type: "string"

  activate: (state) ->
    atom.config.observe "close-tags.emptyTags", (value) =>
      @emptyTags = value

    atom.commands.add "atom-text-editor",
      "close-tags:close": => @closeCurrentTags()

  closeCurrentTags: ->
    editor = atom.workspace.getActivePaneItem()
    for selection in editor.getSelections()
      @closeCurrentTag editor, selection

  closeCurrentTag: (editor, selection) ->
    buffer = editor.getBuffer()
    position = selection.cursor.getBufferPosition().toArray()
    text = buffer.getTextInRange([[0, 0], position])
    stack = @findTagsIn text
    if stack.length
      @insertClosingTag selection, stack.pop()
    else
      console.warn "Couldn't find closing tag."
      atom.beep()

  findTagsIn: (text) ->
    stack = []
    while text
      if text.substr(0, 4) is "<!--"
        text = @handleComment text
      else if text.substr(0, 1) is "<"
        text = @handleTag text, stack
      else
        index = text.indexOf("<")
        if index > -1
          text = text.substr(index)
        else
          break
    stack

  handleComment: (text) ->
    i = 4
    while i < text.length and text.substr(i, 3) isnt "-->"
      i++
    text.substr i + 3

  handleTag: (text, stack) ->
    if match = text.match(/<(\/)?([\w\:\-]+)((?:\s+[\w\:\-]+(?:\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)(\/)?>/)
      if tag = match[2]
        if match[1]
          # closing tag: find matching opening tag (if one exists)
          while stack.length
            break if stack.pop() is tag
        else
          # opening tag, possibly empty
          stack.push tag unless match[4] or @isEmpty(tag)
      text.substr match[0].length
    else
      text.substr 1

  insertClosingTag: (selection, tag) ->
    selection.insertText "</#{tag}>"

  isEmpty: (tag) ->
    @emptyTags.indexOf(tag.toLowerCase()) > -1
