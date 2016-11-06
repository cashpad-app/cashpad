import { map, reduce, forEach, filter, merge, some, every, includes } from 'lodash';
import abbrev from 'abbrev';
import parser from './generatedParser.js';

const errors = {};
let flatListOfLines,
  computed;


const parseAndCompute = (textInput) => {
  const parsed = parser.parse(textInput);
  return computeFromParsed(parsed);
};

const computeFromParsed = (parsed) => {
  flatListOfLines = getFlatListOfLines(parsed.group.lines, parsed.group.context);
  computed = map(flatListOfLines, line => computeLine(line));
  return computed;
};

// get error map by line keys, to be called after computeFromParsed
const getErrors = () => errors;

// flatten context into each line
// TODO take care of abbreviations
const getFlatListOfLines = (lines, context) => {
  return lines.reduce((flatList, line) => {
      if (line.group) { // line is actually a group...
        const nestedFlatList = getFlatListOfLines(line.group.lines, mergeContext(context, line.group.context, line.group.line));
        flatList = flatList.concat(nestedFlatList);
      } else {
        line.context = {};
        line.context.people = context.people;
        flatList.push(line);
      }
      return flatList;
    },
    []
  );
};

// merge context for nexted groups
const mergeContext = (parentContext, childContext, lineNumber) => {
  const context = {};
  // merge people
  if (childContext.people) {
    context.people = childContext.people;
  } else if (childContext.people_delta) {
    context.people = [].concat(parentContext.people); // makes copy of list
    childContext.people_delta.forEach(person => {
      if (person.mod === '+') {
        if (some(parentContext.people, (name) => name === person.name)) {
          addError('PERSON_ADDED_ALREADY_IN_CONTEXT_WARNING', lineNumber, null, {name: person.name});
        } else {
          context.people.push(person.name);
        }
      } else if (person.mod === '-') {
        if (some(parentContext.people, (name) => name === person.name)){
          context.people = filter(context.people, (name) => name !== person.name);
        } else {
          addError('PERSON_REMOVED_NOT_IN_CONTEXT_WARNING', lineNumber, null, {name: person.name});
        }
      }
    });
  }
  return context;
};


// compute balance, spent and given for each line
const computeLine = (line) => {
  // preprocessing tasks..
  preprocessLine(line);
  // validation tasks..
  validateLine(line);
  // intermediate computation steps
  const mapSum = (array, fn) => {
    fn = fn || ((x) => x);
    return array.reduce((a, b) => a + (fn(b) || 0), 0);
  };

  const totalSpentAmount = mapSum(line.payers, (x) => x.amount);
  const totalFixedAmount = mapSum(line.beneficiaries, (x) => x.fixedAmount);
  const totalOffset = mapSum(line.beneficiaries, (x) => x.modifiers.offset);
  const totalMultiplier = mapSum(line.beneficiaries, (x) => x.modifiers.multiplier);
  const amountToDivide = (totalSpentAmount - totalFixedAmount - totalOffset);
  const amountForEachOne = (amountToDivide / totalMultiplier);
  line.computing = {
    totalSpentAmount: totalSpentAmount,
    totalOffset: totalOffset,
    totalMultiplier: totalMultiplier,
    totalFixedAmount: totalFixedAmount,
    amountToDivide: amountToDivide,
    amountForEachOne: amountForEachOne
  };
  // compute balance
  line.computed = {
    balance: {},
    given: {},
    spent: {}
  };
  forEach(line.beneficiaries, (ben) => {
    // spent
    line.computed.spent[ben.name] = ben.fixedAmount || (amountForEachOne * ben.modifiers.multiplier + ben.modifiers.offset);
    // set given to 0 as default for beneficiaries
    line.computed.given[ben.name] = 0;
  });
  // given
  forEach(line.payers, (payer) => {
    line.computed.given[payer.name] = payer.amount;
    line.computed.spent[payer.name] = line.computed.spent[payer.name] || 0;
  });
  // validation and proportional split ($)
  const bensTotalSpentAmount = reduce(line.computed.spent, (acc, v) => acc + v);
  if (bensTotalSpentAmount !== totalSpentAmount) {
    if (getOption(line, 'splitProportionally')) {
      const toDistribute = totalSpentAmount - bensTotalSpentAmount;
      line.computed.spent = map(line.computed.spent, (v) => v + (v / bensTotalSpentAmount * toDistribute));
    } else {
      addError('PAYED_AMOUNT_NOT_MATCHING_ERROR', line.line, line);
    }
  }
  // compute balance
  forEach(line.computed.spent, (v, person) => {
    line.computed.balance[person] = line.computed.given[person] - line.computed.spent[person];
  });
  // return line object
  return line;
};

const preprocessLine = (line) => {
  // complete payers' and bens' names if abbreviated using current context
  const abbreviations = abbrev(line.context.people);
  forEach(line.payers, payer => payer.name = abbreviations[payer.name] || payer.name);

  if (line.beneficiaries) {
    forEach(line.beneficiaries, (ben) => ben.name = abbreviations[ben.name] || ben.name);
  } else {
    // add beneficiaries from context if none is defined
    line.beneficiaries = map(line.context.people, (name) => ({ name }));
  }

  // add remaining beneficiaries if option group is present ...
  const addMissingBeneficiaries = getOption(line, 'group');

  if (addMissingBeneficiaries) {
    const missingBeneficiaries = filter(line.context.people, (personName) => !some(line.beneficiaries, (ben) => ben.name === personName));
    forEach(missingBeneficiaries, (name) => line.beneficiaries.push({ name }));
  }
  // set defaults for offset and multiplier
  line.beneficiaries = map(line.beneficiaries, (ben) => {
    const defaults = {
      modifiers: {
        offset: 0,
        multiplier: ben.fixedAmount ? null : 1
      }
    };
    return merge(defaults, ben);
  });
};

const validateLine = (line) => {
  line.errors = line.errors || [];
  line.warnings = line.warnings || [];
  // throw an error if a non existing beneficiary or payer is found
  const alienBeneficiaries = filter(line.beneficiaries, (ben) => !some(line.context.people, (personName) => personName === ben.name));
  const alienPayers = filter(line.payers, (payer) => !some(line.context.people, (personName) => personName === payer.name));
  const alienPersons = map(alienBeneficiaries.concat(alienPayers), (p) => p.name);
  if (alienPersons.length > 0) {
    addError('ALIEN_PERSON_ERROR', line.line, line, { alienPersons });
  }
};

const getOption = (line, optionName) => filter(line.options, (x) => x.name === optionName)[0];

const addError = (code, lineNumber, lineObject, options) => {
  lineObject = lineObject || null;
  options = options || { alienPersons: [] };
  const pluralize = (list, singular, plural) => list.length > 1 ? plural : singular;
  const errors = getErrors();
  errors[lineNumber] = errors[lineNumber] || [];
  const alienPersons = options.alienPersons || [];
  const verb = pluralize(alienPersons, 'is', 'are');

  const errorTypes = {
    ALIEN_PERSON_ERROR: {
      message: `${alienPersons.join(', ')} ${verb} not present in the current context`,
      recoverySuggestions: `you should add the missing persons with a @people command. You can edit the current people group with @people ${map(alienPersons, (name) => `+${name}`).join(' ')} `
    },
    PAYED_AMOUNT_NOT_MATCHING_ERROR: {
      message: `total spent amunt computed doesn't sum up to what was spent`,
      recoverySuggestions: `either edit the spent amounts or distribute the remainder among others in the current people group using '...'. If you forgot taxes or tip use '$'`
    },
    PERSON_ADDED_ALREADY_IN_CONTEXT_WARNING: {
      message: `you added ${options.name} but it was already present`,
      recoverySuggestions: `remove +${options.name} from the @people declaration`
    },
    PERSON_REMOVED_NOT_IN_CONTEXT_WARNING: {
      message: `you removed ${options.name} but it was not present`,
      recoverySuggestions: `remove -${options.name} from the @people declaration`
    }
  };

  const e = errorTypes[code];
  e.code = code;
  if (includes(code, 'ERROR')) {
    e.type = 'error';
  } else if (includes(code, 'WARNING')) {
    e.type = 'warning';
  }

  if (lineObject) {
    lineObject.errors.push(e);
  }
  errors[lineNumber].push(e);
};

export default {
  parser,
  parseAndCompute,
  getErrors
};
