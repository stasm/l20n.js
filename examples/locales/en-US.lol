<title "L20n example">
<hello "Hello,&nbsp;world!">

<l20n "L20n">
<intro[$build] {
  dev: "You're using a <em>dev</em> build of {{ l20n }} (with AMD modules).",
  prod: """
    You're using a <em>production-ready single-file</em> version of {{ l20n }}
    (built with make build and found in dist/html).
  """,
 *unknown: "You're using an unknown version of {{ l20n }}."
}>

/* ------------------------------------------------------------------------- */

<button "(empty)"
  value: """
    Button's value with HTML <em>markup</em>?
  """
>

<faq """
  Please consult </p> the <abbr>FAQ</abbr> on our <a>Website</a>.
""">

<inputs """
  There are two inputs in this message.  Translations shouldn't be able to 
  changed the type of the input, and should only be able to change the value
  if the input's type is one of: submit, reset, button.
  <input type="range" placeholder="Translated placeholder" value="ignored">
  <input type="text" placeholder="Ignored placeholder" value="Translated send">
""">


<more """
  Style attribute cannot be changed.  Same goes for href.  Title is okay.
  For <em style="color: red;">more</em> information, 
  visit <a href="http://evil.com" title="Harmless link">L20n.org</a>.
""">
