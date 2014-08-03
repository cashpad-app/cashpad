requirejs.config
  baseUrl: "lib"
  paths:
    app: '..'
    jquery: "//code.jquery.com/jquery-2.1.1.min",
    bootstrap:  "//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min"
  shim:
    bootstrap:
      deps: ['jquery']

requirejs ['app/wallet']
