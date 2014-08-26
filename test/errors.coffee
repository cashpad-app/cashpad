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
errors = brain.getErrors()

describe 'brain (errors)', ->

  it 'should produce an error when a beneficiary is not in the current group', ->
    line = computedLines[0]
    (line.errors?).should.be.true
    line.errors.should.have.length 1
    line.errors[0].code.should.eql 'ALIEN_PERSON_ERROR'
    line.errors[0].type.should.eql 'error'
    (line.errors[0].message.indexOf('marco') == -1).should.be.false
    errors[4][0].code.should.eql 'ALIEN_PERSON_ERROR'

  it 'should produce an error when a payer is not in the current group', ->
    line = computedLines[1]
    (line.errors?).should.be.true
    line.errors.should.have.length 1
    line.errors[0].code.should.eql 'ALIEN_PERSON_ERROR'
    line.errors[0].type.should.eql 'error'
    (line.errors[0].message.indexOf('gianni') == -1).should.be.false
    errors[7][0].code.should.eql 'ALIEN_PERSON_ERROR'

  it 'should produce an error when the sum is wrong', ->
    line = computedLines[2]
    (line.errors?).should.be.true
    line.errors.should.have.length 1
    line.errors[0].code.should.eql 'PAYED_AMOUNT_NOT_MATCHING_ERROR'
    line.errors[0].type.should.eql 'error'
    (line.errors[0].message.indexOf('spent') == -1).should.be.false
    errors[10][0].code.should.eql 'PAYED_AMOUNT_NOT_MATCHING_ERROR'

  it 'should produce a warning when adding a person already present', ->
    errors[13][0].code.should.eql 'PERSON_ADDED_ALREADY_IN_CONTEXT_WARNING'

  it 'should produce a warning when removing a person that was not present', ->
    errors[14][0].code.should.eql 'PERSON_REMOVED_NOT_IN_CONTEXT_WARNING'

