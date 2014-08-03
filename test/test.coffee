assert = require 'assert'
should = require 'should'
peg = require 'pegjs'
fs = require 'fs'
requirejs = require('requirejs')
requirejs.config nodeRequire: require
brain = new (requirejs 'dist/lib/geekywalletlib.js')

parser = peg.buildParser fs.readFileSync 'grammar.peg', 'utf8'
wallet = fs.readFileSync 'examples/plain.wallet', 'utf8'
lines = null

describe 'peg parser', ->
  it 'should parse a plain wallet file', ->
    result = parser.parse wallet
    (result != null).should.be.true
    lines = result.group.lines

  describe 'simple line', ->
    it 'should parse the date', ->
      line = lines[0]
      line.date.should.eql new Date(2014, 3, 12)

    it 'should parse the description', ->
      line = lines[0]
      line.desc.should.eql 'plane ticket'

    it 'should parse the beneficiaries', ->
      line = lines[0]
      line.beneficiaries.should.containEql name: 'luca'
      line.beneficiaries.should.containEql name: 'gabriele'
      line.beneficiaries.should.containEql name: 'daniele'

    it 'should parse the payers', ->
      line = lines[0]
      line.payers.should.containEql name: 'luca', amount: 450

    it 'should prase the tags', ->
      line = lines[0]
      (line.tags == null).should.be.true

    it 'should parse the options', ->
      line = lines[0]
      line.options.should.be.empty

    it 'should parse the direction', ->
      line = lines[0]
      line.reversed.should.be.false

describe 'brain', ->
  describe 'simple line', ->
    it 'should inherit people from the context', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[0]
      line.context.people.should.containEql 'luca'
      line.context.people.should.containEql 'gabriele'
      line.context.people.should.containEql 'daniele'

    it 'should inherit beneficiaries from the context when missing', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[1]
      line.beneficiaries.should.have.length 3
      line.beneficiaries.should.containDeep [name: 'luca']
      line.beneficiaries.should.containDeep [name: 'gabriele']
      line.beneficiaries.should.containDeep [name: 'daniele']

    it 'should not inherit beneficiaries from the context when ... is not present', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[2]
      line.beneficiaries.should.have.length 2
      line.beneficiaries.should.containDeep [name: 'luca']
      line.beneficiaries.should.containDeep [name: 'gabriele']
      line.beneficiaries.should.not.containDeep [name: 'daniele']

    it 'should inherit beneficiaries from the context when ... is present', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[3]
      line.beneficiaries.should.have.length 3
      line.beneficiaries.should.containDeep [name: 'luca']
      line.beneficiaries.should.containDeep [name: 'gabriele']
      line.beneficiaries.should.containDeep [name: 'daniele']

    it 'should have a null fixed amount when no amount is specified', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[4]
      (line.beneficiaries.filter((b) -> b.name == 'luca')[0].fixedAmount == null).should.be.true

    it 'should have a null fixed amount when a modifier is specified', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[4]
      (line.beneficiaries.filter((b) -> b.name == 'gabriele')[0].fixedAmount == null).should.be.true

    it 'should compute the fixed amount', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[4]
      line.beneficiaries.filter((b) -> b.name == 'daniele')[0].fixedAmount.should.equal 10
      line.computing.totalFixedAmount.should.equal 10

    it 'should compute the offset', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[5]
      line.beneficiaries.filter((b) -> b.name == 'luca')[0].offset.should.equal -10
      line.beneficiaries.filter((b) -> b.name == 'gabriele')[0].offset.should.equal 5
      line.beneficiaries.filter((b) -> b.name == 'daniele')[0].offset.should.equal 0
      line.computing.totalOffset.should.equal -5

    it 'should compute the multiplier', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[6]
      line.beneficiaries.filter((b) -> b.name == 'luca')[0].multiply.should.equal 1
      line.beneficiaries.filter((b) -> b.name == 'gabriele')[0].multiply.should.equal 2
      line.beneficiaries.filter((b) -> b.name == 'daniele')[0].multiply.should.equal 1
      line.computing.totalMultiply.should.equal 3 # only people with a non-fixed amount are considered

    it 'should compute the total spent amount', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[7]
      line.computing.totalSpentAmount.should.equal 15 + 7 + 18

    it 'should compute the balance', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[7]
      line.computed.balance.luca.should.equal -3
      line.computed.balance.gabriele.should.equal -5
      line.computed.balance.daniele.should.equal 8

    it 'should compute the given amount', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[7]
      line.computed.given.luca.should.equal 7
      line.computed.given.gabriele.should.equal 15
      line.computed.given.daniele.should.equal 18

    it 'should compute the spent amount', ->
      result = parser.parse wallet
      computedLines = brain.computeFromParsed result
      line = computedLines[7]
      line.computed.spent.luca.should.equal 10
      line.computed.spent.gabriele.should.equal 20
      line.computed.spent.daniele.should.equal 10
