L20n JavaScript API
===================

The main abstractions used by the JavaScript API are the `View` and the 
`Service` classes.  Views are responsible for localizing `document` objects in 
HTML.  The Service stores the state of the language negotiation and downloaded 
resources.

If you're using the `web` or the `webcompat` runtime builds (see 
[docs/html][]), each `document` will have its corresponding `View` created 
automatically on startup, as `document.l10n`. 

[docs/html]: https://github.com/l20n/l20n.js/blob/master/docs/html.md

```javascript
var ctx = L20n.getContext();
ctx.linkResource('./locales/strings.l20n');
ctx.requestLocales();
```

When you freeze the context by calling `requestLocales`, the resource files 
will be retrieved, parsed and compiled.  You can listen to the `ready` event 
(emitted by the `Context` instance when all the resources have been compiled) 
and use `ctx.get` and `ctx.getEntity` to get translations synchronously.

Alternatively, you can register callbacks to execute when the context is ready 
(or when globals change and translations need to be updated) with 
`ctx.localize`.

```javascript
ctx.localize(['hello', 'new'], function(l10n) {
  var node = document.querySelector('[data-l10n-id=hello]');
  node.textContent = l10n.entities.hello.value;
  node.classList.remove('hidden');
});
```

### ctx.registerLocales(defaultLocale: String?, availableLocales: Array&lt;String&gt;?)

Register the default locale of the `Context` instance, as well as all other 
locales available to the `Context` instance before the language negotiation. 
Locales are referenced by their [BCP 47 language codes][].

[BCP 47 language codes]: http://tools.ietf.org/html/bcp47

```javascript
ctx.registerLocales('en-US', ['ar', 'es-AR', 'es-ES', 'en-US', 'fr', 'pl']);
```

`defaultLocale` is the original language of the `Context` instance and will be 
used as the last fallback locale if other locales are registered.  If 
it is undefined, or if `registerLocales` hasn't been called at all, the 
`Context` instance will create a special locale called [`i-default`][] to be 
used as the default.

[`i-default`]: http://www.iana.org/assignments/lang-tags/i-default

`availableLocales` is an array of all locales available to the `Context` 
instance.  This array (with `defaultLocale` appended to it if it is not already 
present) will be used to negotiate the fallback chain for the user.  


### ctx.registerLocaleNegotiator(negotiator: Function)

Register a function which will be used to negotiate the locales supported by 
the `Context` instance.  If you don't call this function, L20n will use the 
built-in `Intl.prioritizeLocales` negotiator.

```javascript
ctx.registerLocaleNegotiator(function(available, requested, defLocale) {
  return Intl.prioritizeLocales(available, requested, defLocale);
});
```

`negotiator` is a function which takes the following arguments:

 - `available` - all locales available to the `Context` instance,
 - `requested` - locales preferred by the user,
 - `defLocale` - the default locale to be used as the ultimate fallback,
 - `callback` - the function to call when the negotiation completes (useful for 
   asynchronous negotiators).

It must return an array which is the final fallback chain of locales, or if the 
negotiation is asynchronous, it must return a falsy value and call the 
`callback` argument upon completion.

```javascript
ctx.registerLocaleNegotiator(function(available, requested, defLocale, callback) {
  YourApp.getAllAvailableLanguages(function(allAvailable) {
    var fallbackChain = YourApp.intersect(allAvailable, requested); 
    cb(fallbackChain);
  });
});
```


### ctx.requestLocales(...requestedLocales: String?)

Specify the user's preferred locales for the `Context` instance to negotiate 
against and freeze the `Context` instance.

When a `Context` instance is frozen, no more resources can be added or linked.  
All IO related to fetching the resource files takes place when a `Context` 
instance freezes.  When all resources have been fetched, parsed and compiled, 
the `Context` instance will emit a `ready` event.

The final list of locales supported by the `Context` instance will be 
negotiated asynchronously by the `negotiator` registered by 
`registerLocaleNegotiator`.

```javascript
ctx.requestLocales('pl');
```

```javascript
ctx.requestLocales('fr-CA', 'fr');
```

If `requestedLocales` argument list is empty or undefined, the default locale 
from `registerLocales` will be used.

```javascript
ctx.requestLocales();
```

If `registerLocales` hasn't been called, the special `i-default` locale is 
used, which means that the following minimal code is valid and will result in 
a fully operational `Context` instance.

```javascript
var ctx = L20n.getContext();
ctx.addResource('<hello "Hello, world!">');
ctx.requestLocales();
```

`requestLocales` can be called multiple times after the `Context` instance 
emitted the `ready` event, in order to change the current language fallback 
chain, for instance if requested by the user.


### ctx.supportedLocales

A read-only property which holds the current fallback chain of locales which 
was negotiated between all the available locales, the default locale and the 
user's preferred locales.

```javascript
ctx.registerLocales('en-US', ['en-US', 'fr', 'pl']);
ctx.requestLocales('fr-CA', 'fr');
ctx.ready(function() {
  // ctx.supportedLocales == ['fr'];
});
```


### ctx.addResource(text: String)

Add a string as the content of a resource to the Context instance.  The 
resource is added to all registered locales.

```javascript
ctx.addResource('<hello "Hello, world!">');
```


### ctx.linkResource(uri: String)

Add a resource identified by a URL to the Context instance.  The resource is 
added to all registered locales.

```javascript
ctx.linkResource('../locale/app.lol');
```



### ctx.linkResource(template: Function)

Add a resource identified by a URL to the Context instance.  The URL is 
constructed dynamically when you call `requestLocales`.  The function passed to 
`linkResource` (called a _template function_) takes one argument which is the 
code of the current locale, which needs to be first registered with 
`registerLocales`.

```javascript
ctx.linkResource(function(locale) {
  return '../locales/' + locale + '/strings.lol';
});
```

The resource is added to all registered locales.  If there are no registered 
locales (see `registerLocales`), the default `i-default` locale is used.  In 
this case, `addResource(String)` and `linkResource(String)` might be better 
suited for adding resources.


### ctx.addEventListener(event: String, callback: Function)

Register an event handler on the Context instance.

Currently available event types:

 - `ready` - fired when all resources are available and the `Context` instance 
   is ready to be used.  This event is also fired after each change to locale 
   order (retranslation).

 - `error` - fired when an error occurs which prevents the `Context` instance 
   from working correctly or when the existing translations are buggy.  The 
   error object is passed as the first argument to `callback`.  These errors 
   include:

   - native JavaScript errors (`TypeError`, `ReferenceError` etc.),

   - `Context.RuntimeError`, when an entity is missing or broken in all 
     supported locales;  in this case, L20n will show the the best available 
     fallback of the requested entity in the UI:  the source string as found in 
     the resource, or the identifier.

   - `Context.TranslationError`, when the translation is present but broken 
     in one of supported locales;  the `Context` instance will try to retrieve 
     a fallback translation from the next locale in the fallback chain,

   - `Parser.Error`, when L20n is unable to parse the syntax of a resource; 
     this might result in entities being broken which in turn can lead to above 
     error being emitted.

 - `warning` - fired when a less serious error occurs from which the `Context` 
   instance can recover gracefully and try to fetch a translations from 
   a fallback locale.  The error object is passed as the first argument to 
   `callback` and can be one of the following:

   - `Context.Error`, when there are problems with setting up resources (e.g. 
     a 404 error when fetching a resource file, or recursive `import` 
     statements in resource files),

   - `Context.TranslationError`, when there is a missing translation 
     in one of supported locales;  the `Context` instance will try to retrieve 
     a fallback translation from the next locale in the fallback chain,

   - `Compiler.Error`, when L20n is unable to evaluate an entity to a string; 
     there are two types of errors in this category: `Compiler.ValueError`, 
     when L20n can still try to use the literal source string of the entity as 
     fallback, and `Compiler.IndexError` otherwise.


### ctx.removeEventListener(event: String, callback: Function)

Remove an event listener previously registered with `addEventListener`.


### ctx.get(id: String, ctxdata: Object?)

Retrieve a string value of an entity called `id`.

If passed, `ctxdata` is a simple hash object with a list of variables that
extend the context data available for the evaluation of this entity.

Returns a string.


### ctx.getEntity(id: String, ctxdata: Object?)

Retrieve an object with data evaluated from an entity called `id`.

If passed, `ctxdata` is a simple hash object with a list of variables that
extend the context data available for the evaluation of this entity.

Returns an object with the following properties:

 - `value`: the string value of the entity,
 - `attributes`: an object of evaluated attributes of the entity,
 - `globals`: a list of global variables used while evaluating the entity,
 - `locale`: locale code of the language the entity is in;  it can be different 
   than the first locale in the current fallback chain if the entity couldn't 
   be evaluated and a fallback translation had to be used.


### ctx.ready(callback: Function)

Fires the function passed as argument as soon as the context is available.

If the context is available when the function is called, it fires the callback
instantly. 
Otherwise it sets the event listener and fire as soon as the context is ready.

After that, each time locale list is modified (retranslation case) the callback 
will be executed.
