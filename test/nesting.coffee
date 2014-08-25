assert = require 'assert'
should = require 'should'
peg = require 'pegjs'
fs = require 'fs'
requirejs = require('requirejs')
requirejs.config nodeRequire: require
brain = new (requirejs 'dist/lib/geekywalletlib.js')

grammar = fs.readFileSync 'lib/syntax/grammar.peg', 'utf8'
parser = peg.buildParser grammar
wallet = fs.readFileSync 'examples/nested.wallet', 'utf8'
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

describe 'brain', ->
  describe 'nested line', ->
    it 'should not inherit beneficiaries of the nested context', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[0]
      line.beneficiaries.should.have.length 1
      line.beneficiaries.should.containDeep [name: 'gabro']

    it 'should inherit beneficiaries from the nested context', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[1]
      line.beneficiaries.should.have.length 2
      line.beneficiaries.should.containDeep [name: 'gabro']
      line.beneficiaries.should.containDeep [name: 'dani']

    it 'should compute the people delta in the nested context', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[2]
      line.context.people.should.have.length 2
      line.context.people.should.containEql 'luca'
      line.context.people.should.containEql 'dani'
      line.context.people.should.not.containEql 'gabro'
