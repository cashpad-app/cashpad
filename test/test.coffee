assert = require "assert"
should = require('should')
peg = require "pegjs"
fs = require "fs"
parser = peg.buildParser fs.readFileSync('grammar.peg', 'utf8')
wallet = fs.readFileSync('examples/plain.wallet', 'utf8')
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
      (line.options == null).should.be.true

    it 'should parse the direction', ->
      line = lines[0]
      line.reversed.should.be.false
