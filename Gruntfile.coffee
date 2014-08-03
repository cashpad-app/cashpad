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


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-mocha-test'

  grunt.registerTask 'test', ['coffee', 'mochaTest']
