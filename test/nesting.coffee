assert = require 'assert'
should = require 'should'
peg = require 'pegjs'
fs = require 'fs'
requirejs = require('requirejs')
requirejs.config nodeRequire: require
brain = new (requirejs 'dist/lib/geekywalletlib.js')

grammar = fs.readFileSync 'lib/syntax/grammar.peg', 'utf8'
parser = peg.buildParser grammar
wallet = fs.readFileSync 'examples/plain.wallet', 'utf8'
lines = null

describe 'peg parser', ->
  it 'should parse a nested wallet file', ->
    try
      result = parser.parse wallet
      (result != null).should.be.tree
      lines = result.group.lines
    catch e
      console.log(e)
      assert false
