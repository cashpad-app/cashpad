assert = require 'assert'
should = require 'should'
peg = require 'pegjs'
fs = require 'fs'
requirejs = require('requirejs')
requirejs.config nodeRequire: require
brain = new (requirejs 'dist/lib/geekywalletlib.js')

parser = peg.buildParser fs.readFileSync 'lib/syntax/grammar.peg', 'utf8'
wallet = fs.readFileSync 'examples/errors.wallet', 'utf8'
lines = parser.parse wallet
computedLines = brain.computeFromParsed lines

describe 'brain (errors)', ->

  it 'should produce an error when a beneficiary is not in the current group', ->
    line = computedLines[0]
    (line.errors?).should.be.true
    line.errors.should.have.length 1

  it 'should produce an error when a payer is not in the current group', ->
    line = computedLines[1]
    (line.errors?).should.be.true
    line.errors.should.have.length 1

  it.skip 'should produce an error when the sum is wrong', ->
    line = computedLines[2]
    (line.errors?).should.be.true
    line.errors.should.have.length 1
