requirejs.config
  baseUrl: "lib"
  paths:
    app: '..'
    jquery: "//code.jquery.com/jquery-2.1.1.min",
    bootstrap: "//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min"
    goog: '../bower_components/requirejs-plugins/src/goog'
    async: '../bower_components/requirejs-plugins/src/async'
    propertyParser: '../bower_components/requirejs-plugins/src/propertyParser'
  shim:
    bootstrap:
      deps: ['jquery']

requirejs ['app/wallet']
