module.exports = (grunt) ->

  grunt.initConfig

    clean: ['dist']

    copy:
      bower:
        files: [
          expand: true
          src: 'bower_components/**'
          dest: 'dist/'
        ]

    coffee:
      test:
        files:
          'test/test.js': 'test/*.coffee'
      lib:
        files: [
          expand: true
          src: '**/*.coffee'
          dest: 'dist/lib'
          cwd: 'lib'
          ext: '.js'
        ]
      app:
        files:
          'dist/app.js': 'app/app.coffee'
          'dist/wallet.js': 'app/scripts/**/*.coffee'

    jade:
      app:
        files: [
          expand: true
          src: '**/*.jade'
          dest: 'dist'
          cwd: 'app/views'
          ext: '.html'
        ]

    mochaTest:
      test:
        options:
          reporter: 'spec'
        src: ['test/**/*.js']

    watch:
      app:
        files: [
          '**/*.coffee'
          '**/*.jade'
        ]
        tasks: ['build']
      test:
        files: ['**/*.coffee']
        tasks: ['test']
        options:
          atBegin: true

    peg:
      wallet:
        src: 'lib/syntax/grammar.peg'
        dest: 'dist/lib/syntax/parser.js'
        options:
          exportVar: 'parser'
          trackLineAndColumn: 'true'

    file_append:
      default_options:
        files:
          'dist/lib/syntax/parser.js':
            append: 'define(function() { return parser; });'
            input: 'dist/lib/syntax/parser.js'

    connect:
      options:
        port: 9000
        hostname: '0.0.0.0'
        livereload: 35729
      dist:
        options:
          base: 'dist'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-peg'
  grunt.loadNpmTasks 'grunt-file-append'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-copy'

  grunt.registerTask 'test', ['coffee:test', 'coffee:lib', 'mochaTest']
  grunt.registerTask 'build', ['clean', 'copy:bower', 'coffee:lib', 'coffee:app', 'jade:app', 'peg', 'file_append']
  grunt.registerTask 'serve', ['build', 'connect', 'watch:app']
