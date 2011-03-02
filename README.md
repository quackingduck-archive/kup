# Kup

Kup. A small all-coffee template language where elements are described with
css-like syntax

Example:

    template = Kup ->
      n '.field', ->
        n '.placeholder', 'Description'
        n '.focused' if @focused
        n 'textarea.field', { readonly: not @editable }, @val

produces the same output (but does not compile to)

    template = (context) -> (->
      '<div class="field">'+
        '<div class="placeholder">Description</div>'+
        (if @focused then '<div class="focused"></div>' else '')+
        '<textarea class="field"'+(if not @editable then ' readonly' else '')+'>'+@val+'</textarea>'+
      '</div>'
      ).call(context)

To render a template you just call the function with a context object:

    template(val: "Some Description", editable: true, focused: false)

---

Based on:

* CoffeeKup - https://github.com/mauricemach/coffeekup
* jQuery Builder - https://github.com/quackingduck/jquery.builder.js
