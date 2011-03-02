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

kup.version = '0.1'

skeleton = (context = {}, ck_options = {}) ->
  ck_options.format ?= off
  ck_options.autoescape ?= on
  ck_buffer = []

  n = (css_str, opts...) ->
    match = css_str.match /^([^\.].+?)?(#.+?)?(\..+?)?$/
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

  tag = -> name = arguments[0]; delete arguments[0]; ck_tag(name, arguments)

  text = (txt) ->
    ck_buffer.push String(txt)
    null

  h = (txt) ->
    String(txt).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

  comment = (cmt) ->
    text "<!--#{cmt}-->"
    text '\n' if ck_options.format

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

  ck_indent = -> text ck_repeat('  ', ck_tabs) if ck_options.format

  ck_tag = (name, opts) ->
    ck_indent()
    text "<#{name}"

    for o in opts
      text ck_render_attrs(o) if typeof o is 'object'

    if name in ck_self_closing
      text ' />'
      text '\n' if ck_options.format
    else
      text '>'

      for o in opts
        switch typeof o
          when 'string', 'number'
            text ck_esc(o)
          when 'function'
            text '\n' if ck_options.format
            ck_tabs++
            result = o.call context
            if typeof result is 'string'
              ck_indent()
              text ck_esc(result)
              text '\n' if ck_options.format
            ck_tabs--
            ck_indent()
      text "</#{name}>"
      text '\n' if ck_options.format

    null

  coffeescript = (code) ->
    script ";(#{code})();"

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
