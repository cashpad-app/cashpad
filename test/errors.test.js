import peg from 'pegjs';
import fs from 'fs';
import brain from '../src/app.js';

const wallet = fs.readFileSync('examples/errors.wallet', 'utf8');
const computedLines = brain.parseAndCompute(wallet);
const errors = brain.getErrors();

describe('brain (errors)', function() {

  it('should produce an error when a beneficiary is not in the current group', () => {
    const line = computedLines[0];
    expect(line.errors).not.toBeNull();
    expect(line.errors).toHaveLength(1);
    expect(line.errors[0].code).toBe('ALIEN_PERSON_ERROR');
    expect(line.errors[0].type).toBe('error');
    expect(line.errors[0].message).toContain('marco');
    expect(errors[4][0].code).toBe('ALIEN_PERSON_ERROR');
  });

  it('should produce an error when a payer is not in the current group', () => {
    const line = computedLines[1];
    expect(line.errors).not.toBeNull();
    expect(line.errors).toHaveLength(1);
    expect(line.errors[0].code).toBe('ALIEN_PERSON_ERROR');
    expect(line.errors[0].type).toBe('error');
    expect(line.errors[0].message).toContain('gianni');
    expect(errors[7][0].code).toBe('ALIEN_PERSON_ERROR');
  });

  it('should produce an error when the sum is wrong', () => {
    const line = computedLines[2];
    expect(line.errors).not.toBeNull();
    expect(line.errors).toHaveLength(1);
    expect(line.errors[0].code).toBe('PAYED_AMOUNT_NOT_MATCHING_ERROR');
    expect(line.errors[0].type).toBe('error');
    expect(line.errors[0].message).toContain('spent');
    expect(errors[10][0].code).toBe('PAYED_AMOUNT_NOT_MATCHING_ERROR');
  });

});

