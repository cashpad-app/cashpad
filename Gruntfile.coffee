module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      compile:
        files:
          'test/test.js': 'test/*.coffee',
          'dist/lib/geekywalletlib.js': 'lib/geekywalletlib.coffee'

    mochaTest:
      test:
        options:
          reporter: 'spec'
        src: ['test/**/*.js']

    watch:
      test:
        files: ['**/*.coffee']
        tasks: ['test']
        options:
          atBegin: true

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'test', ['coffee', 'mochaTest']
