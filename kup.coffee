kup = window.Kup = (template, options = {}) ->
  options.helpers ?= {}

  template = String(template)
  code = skeleton

  for k, v of options.helpers
    if typeof v is 'function' then code += "var #{k} = #{v};"
    else code += "var #{k} = #{JSON.stringify v};"

  code += "(#{template}).call(context);"
  code += "return ck_buffer.join('');"

  new Function('context', 'ck_options', code)

kup.version = '0.5'

# If jQuery is present then Kup.$ can be used to generate a jQuery object
# that hasn't yet been inserted into the DOM
#
# E.g. `Kup.$( -> '.foo')` is equivalent to `$('<div class="foo"></div>')`
if window.jQuery
  kup.$ = (template) -> window.jQuery kup(template)()

skeleton = (context = {}, ck_options = {}) ->
  ck_options.format ?= off
  ck_options.autoescape ?= on
  ck_buffer = []
  ck_prev_underscore = window._

  _ =
    if ck_prev_underscore
      (->
        f = ->
          if typeof arguments[0] is 'string'
            if arguments[0][0] is '<'
              append arguments[0]
            else
              css_tag.apply context, arguments
          else
            ck_prev_underscore.apply null, arguments
        f.prototype = ck_prev_underscore.prototype
        f
      )()
    else
      -> css_tag.apply context, arguments

  # deprecated interface
  n = ->
    ck_warn "n method deprecated, use _"
    _.apply context, arguments

  css_tag = (css_str, opts...) ->
    return append css_str if css_str[0] == '<'

    match = css_str.match /^([^\.]+?)?(#.+?)?(\..+?)?$/
    throw "#{css_str} not a valid tag string" unless match?
    [tag_name,id,classes] = match[1..match.length]
    tag_name or= 'div'
    attrs = {}
    attrs.id = id[1..-1] if id?
    attrs.class = classes[1..classes.length].split('.').join(' ') if classes?

    for o in opts
      if o.class? and attrs.class?
        attrs.class += ' '+o.class
        delete o['class']

    opts.unshift attrs
    ck_tag tag_name, opts

  # deprecated interface
  tag = ->
    ck_warn "tag method deprecated, use _"
    name = arguments[0]; delete arguments[0];
    ck_tag(name, arguments)

  text = (txt) ->
    append h txt

  h = (txt) ->
    String(txt).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

  comment = (cmt) ->
    append "<!--#{cmt}-->"
    append '\n' if ck_options.format

  append = (html) ->
    ck_buffer.push String(html)
    null

  coffeescript = (code) ->
    script ";(#{code})();"

  ck_tag = (name, opts) ->
    ck_indent()
    append "<#{name}"

    for o in opts
      append ck_render_attrs(o) if typeof o is 'object'

    if name in ck_self_closing
      append ' />'
      append '\n' if ck_options.format
    else
      append '>'

      for o in opts
        switch typeof o
          when 'string', 'number'
            append ck_esc(o)
          when 'function'
            append '\n' if ck_options.format
            ck_tabs++
            result = o.call context
            if typeof result is 'string'
              ck_indent()
              append ck_esc(result)
              append '\n' if ck_options.format
            ck_tabs--
            ck_indent()
      append "</#{name}>"
      append '\n' if ck_options.format

    null

  ck_render_attrs = (obj) ->
    str = ''
    for k, v of obj
      # thanks github.com/aeosynth/ck
      if typeof v is 'boolean'
        str += " #{k}" if v is true
      else
        str += " #{k}=\"#{ck_esc v}\""
    str

  ck_self_closing = ['area', 'base', 'basefont', 'br', 'col', 'frame', 'hr', 'img', 'input', 'link', 'meta', 'param']

  ck_esc = (txt) ->
    if ck_options.autoescape then h(txt) else String(txt)

  ck_tabs = 0

  ck_repeat = (string, count) -> Array(count + 1).join string

  ck_indent = -> append ck_repeat('  ', ck_tabs) if ck_options.format

  ck_warn = (msg) ->
    console.warn msg if console and console.warn

  null

support = '''
  var __slice = Array.prototype.slice;
  var __hasProp = Object.prototype.hasOwnProperty;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  var __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype;
    return child;
  };
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
'''

skeleton = String(skeleton).replace(/function\s*\(context, ck_options\)\s*\{/, '').replace /return null;\s*\}$/, ''
skeleton = support + skeleton
