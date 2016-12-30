import peg from 'pegjs';
import fs from 'fs';
import uniq from 'lodash/uniq'

import brain from '../src/app.js';

const wallet = fs.readFileSync('examples/valid.wallet', 'utf8');
const computedLines = brain.parseAndCompute(wallet);
const errors = brain.getErrors();
const parser = brain.parser;
const result = parser.parse(wallet);
const lines = result.group.lines;

describe('peg parser', () => {
  it('should parse a valid wallet file', () => {
    expect(result).not.toBeNull();
  });

  describe('simple line', () => {
    const line = lines[0];

    it('should parse the date', () => {
      expect(line.date).toEqual(new Date(2014, 3, 12));
    });

    it('should parse the description', () => {
      expect(line.desc).toBe('plane ticket');
    });

    it('should parse the beneficiaries', () => {
      expect(line.beneficiaries).toContainEqual({ name: 'luca' });
      expect(line.beneficiaries).toContainEqual({ name: 'gabriele' });
      expect(line.beneficiaries).toContainEqual({ name: 'daniele' });
    });

    it('should parse the payers', () => {
      expect(line.payers).toContainEqual({ name: 'luca', amount: 450 });
    });

    // TODO: check whether tags functionality is still valid
    xit('should parse the tags', () => {
      expect(line.tags).not.toBeNull();
    });

    it('should parse the options', () => {
      expect(line.options).toHaveLength(0);
    });

    it('should parse the direction', () => {
      expect(line.reversed).toBe(false);
    });

    it('should parse inline comments', () => {
      expect(line.comment).toBe('a comment');
    });

    it('should parse -> ...', () => {
      const line = lines[16];
      expect(line.payers).toContainEqual({ name: 'daniele', amount: 96 });
      expect(line.beneficiaries).toHaveLength(0);
    });

    it('should parse $', () => {
      const line = lines[17];
      expect(line.options).toContainEqual({ name: 'splitProportionally' });
    });

  });

});

describe('brain', () =>
  describe('simple line', () => {
    it('should inherit people from the context', () => {
      const line = computedLines[0];
      expect(line.context.people).toContainEqual('luca');
      expect(line.context.people).toContainEqual('gabriele');
      expect(line.context.people).toContainEqual('daniele');
    });

    it('should inherit beneficiaries from the context when missing', () => {
      const line = computedLines[1];
      expect(line.beneficiaries).toHaveLength(3);
      expect(line.beneficiaries[0].name).toBe('luca');
      expect(line.beneficiaries[1].name).toBe('gabriele');
      expect(line.beneficiaries[2].name).toBe('daniele');
    });

    it('should not inherit beneficiaries from the context when ... is not present', () => {
      const line = computedLines[2];
      expect(line.beneficiaries).toHaveLength(2);
      expect(line.beneficiaries[0].name).toBe('luca');
      expect(line.beneficiaries[1].name).toBe('gabriele');
    });

    it('should inherit beneficiaries from the context when ... is present', () => {
      const line = computedLines[3];
      expect(line.beneficiaries).toHaveLength(3);
      expect(line.beneficiaries[0].name).toBe('luca');
      expect(line.beneficiaries[1].name).toBe('gabriele');
      expect(line.beneficiaries[2].name).toBe('daniele');
    });

    it('should inherit beneficiaries from the context when offsets and ... are present', () => {
      const line = computedLines[12];
      expect(line.beneficiaries).toHaveLength(3);
      expect(line.beneficiaries[0].name).toBe('gabriele');
      expect(line.beneficiaries[1].name).toBe('luca');
      expect(line.beneficiaries[2].name).toBe('daniele');
    });

    it('should inherit beneficiaries from the context when offsets, fixed amounts and ... are present', () => {
      const line = computedLines[13];
      expect(line.beneficiaries).toHaveLength(3);
      expect(line.beneficiaries[0].name).toBe('gabriele');
      expect(line.beneficiaries[1].name).toBe('luca');
      expect(line.beneficiaries[2].name).toBe('daniele');
    });

    it('should not inherit beneficiaries from the context when a non-fixed amount is present', () => {
      const line = computedLines[14];
      expect(line.beneficiaries).toHaveLength(2);
      expect(line.beneficiaries[0].name).toBe('gabriele');
      expect(line.beneficiaries[1].name).toBe('luca');
    });

    it('should not inherit beneficiaries from the context when only fixed amounts are present', () => {
      const line = computedLines[15];
      expect(line.beneficiaries).toHaveLength(2);
      expect(line.beneficiaries[0].name).toBe('gabriele');
      expect(line.beneficiaries[1].name).toBe('luca');
    });

    it('should not have a fixed amount when no amount is specified', () => {
      const line = computedLines[4];
      expect(line.beneficiaries.filter(b => b.name === 'luca')[0].fixedAmount).toBeUndefined();
    });

    it('should not have a fixed amount when a modifier is specified', () => {
      const line = computedLines[4];
      expect(line.beneficiaries.filter(b => b.name === 'gabriele')[0].fixedAmount).toBeUndefined();
    });

    it('should compute the fixed amount', () => {
      const line = computedLines[4];
      expect(line.beneficiaries.filter(b => b.name === 'daniele')[0].fixedAmount).toBe(10);
      expect(line.computing.totalFixedAmount).toBe(10);
    });

    it('should compute the offset', () => {
      const line = computedLines[5];
      expect(line.beneficiaries.filter(b => b.name === 'luca')[0].modifiers.offset).toBe(-10);
      expect(line.beneficiaries.filter(b => b.name === 'gabriele')[0].modifiers.offset).toBe(5);
      expect(line.beneficiaries.filter(b => b.name === 'daniele')[0].modifiers.offset).toBe(0);
      expect(line.computing.totalOffset).toBe(-5);
    });

    it('should compute the multiplier', () => {
      const line = computedLines[6];
      expect(line.beneficiaries.filter(b => b.name === 'luca')[0].modifiers.multiplier).toBe(1);
      expect(line.beneficiaries.filter(b => b.name === 'gabriele')[0].modifiers.multiplier).toBe(2);
      expect(line.beneficiaries.filter(b => b.name === 'daniele')[0].modifiers.multiplier).toBeNull();
      expect(line.computing.totalMultiplier).toBe(3);
    });

    it('should compute the total spent amount', () => {
      const line = computedLines[7];
      expect(line.computing.totalSpentAmount).toBe(15 + 7 + 18);
    });

    it('should compute the balance', () => {
      const line = computedLines[7];
      expect(line.computed.balance.luca).toBe(-3);
      expect(line.computed.balance.gabriele).toBe(-5);
      expect(line.computed.balance.daniele).toBe(8);
    });

    it('should compute the given amount', () => {
      const line = computedLines[7];
      expect(line.computed.given.luca).toBe(7);
      expect(line.computed.given.gabriele).toBe(15);
      expect(line.computed.given.daniele).toBe(18);
    });

    it('should compute the spent amount', () => {
      const line = computedLines[7];
      expect(line.computed.spent.luca).toBe(10);
      expect(line.computed.spent.gabriele).toBe(20);
      expect(line.computed.spent.daniele).toBe(10);
    });

    it('should compute the balance when a payer is not also a beneficiary', () => {
      const line = computedLines[9];
      expect(line.beneficiaries).toHaveLength(1);
      expect(line.beneficiaries[0].name).toBe('luca');
      expect(line.payers).toHaveLength(1);
      expect(line.payers[0].name).toBe('gabriele');
      expect(line.computed.balance.luca).toBe(-20);
      expect(line.computed.balance.gabriele).toBe(20);
    });

    it('should contain both payers and beneficiaries in computed.balance', () => {
      const line = computedLines[10];
      const bens = line.beneficiaries.map(b => b.name);
      const payers = line.payers.map(p => p.name);
      const names = Object.keys(line.computed.balance || {}).sort();
      const expectedNames = uniq(payers.concat(bens)).sort();
      expect(names).toEqual(expectedNames);
    });

    it('should allow for abbreviations', () => {
      const line = computedLines[8];
      expect(line.beneficiaries).toHaveLength(1);
      expect(line.payers).toHaveLength(1);
      expect(line.beneficiaries[0].name).toBe('daniele');
      expect(line.payers[0].name).toBe('gabriele');
    });

    it('should error on ambiguous abbreviations', () => {
      const content = '@people luca giovanni gianfrancioschio\ntest: gio 10 -> luca gi';
      expect(brain.parseAndCompute(content)).toThrow();
    });

    it('should ignore the case of people names', () => {
      const line = computedLines[11];
      const names = Object.keys(line.computed.balance || {});
      expect(names).toHaveLength(2);
    });

    // FIXME: this should actually work
    xit('should proportionally split the expense using $', () => {
      const line = computedLines[17];
      expect(line.computed.spent.gabriele).toBe(10.4);
      expect(line.computed.spent.daniele).toBe(10.4);
      expect(line.computed.spent.luca).toBe(5.2);
    });
  })
);
