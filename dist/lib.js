(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty;

  define(function() {
    var Brain;
    Array.prototype.sum = function(fn) {
      if (fn == null) {
        fn = function(x) {
          return x;
        };
      }
      return this.reduce((function(a, b) {
        var elem;
        elem = fn(b) || 0;
        return a + elem;
      }), 0);
    };
    if (!Array.prototype.some) {
      Array.prototype.some = function(f) {
        var x;
        return ((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = this.length; _i < _len; _i++) {
            x = this[_i];
            if (f(x)) {
              _results.push(x);
            }
          }
          return _results;
        }).call(this)).length > 0;
      };
    }
    if (!Array.prototype.every) {
      Array.prototype.every = function(f) {
        var x;
        return ((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = this.length; _i < _len; _i++) {
            x = this[_i];
            if (f(x)) {
              _results.push(x);
            }
          }
          return _results;
        }).call(this)).length === this.length;
      };
    }
    Brain = (function() {
      function Brain() {
        this.getOption = __bind(this.getOption, this);
        this.validateLine = __bind(this.validateLine, this);
        this.preprocessLine = __bind(this.preprocessLine, this);
        this.computeLine = __bind(this.computeLine, this);
        this.getFlatListOfLines = __bind(this.getFlatListOfLines, this);
        this.computeFromParsed = __bind(this.computeFromParsed, this);
      }

      Brain.prototype.computeFromParsed = function(parsed) {
        this.flatListOfLines = this.getFlatListOfLines(parsed.group.lines, parsed.group.context);
        this.computed = this.flatListOfLines.map((function(_this) {
          return function(line) {
            return _this.computeLine(line);
          };
        })(this));
        return this.computed;
      };

      Brain.prototype.getFlatListOfLines = function(lines, context) {
        return lines.reduce(((function(_this) {
          return function(flatList, line) {
            var nestedFlatList;
            if (line.group != null) {
              nestedFlatList = _this.getFlatListOfLines(line.group.lines, _this.mergeContext(context, line.group.context));
              flatList = flatList.concat(nestedFlatList);
            } else {
              line.context = {};
              line.context.people = context.people;
              flatList.push(line);
            }
            return flatList;
          };
        })(this)), []);
      };

      Brain.prototype.mergeContext = function(parentContext, childContext) {
        var context, person, _fn, _i, _len, _ref;
        context = {};
        if (childContext.people != null) {
          context.people = childContext.people;
        } else if (childContext.people_delta != null) {
          context.people = [].concat(parentContext.people);
          _ref = childContext.people_delta;
          _fn = (function(_this) {
            return function() {
              if (person.mod === '+') {
                if (parentContext.people.some(function(name) {
                  return name === person.name;
                })) {

                } else {
                  return context.people.push(person.name);
                }
              } else if (person.mod === '-') {
                if (parentContext.people.some(function(name) {
                  return name === person.name;
                })) {
                  return context.people = context.people.filter(function(name) {
                    return name !== person.name;
                  });
                } else {

                }
              }
            };
          })(this);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            person = _ref[_i];
            _fn();
          }
        }
        return context;
      };

      Brain.prototype.computeLine = function(line) {
        var amountForEachOne, amountToDivide, person, totalFixedAmount, totalMultiplier, totalOffset, totalSpentAmount, val, _fn, _ref;
        this.preprocessLine(line);
        this.validateLine(line);
        totalSpentAmount = line.payers.sum(function(x) {
          return x.amount;
        });
        totalFixedAmount = line.beneficiaries.sum(function(x) {
          return x.fixedAmount;
        });
        totalOffset = line.beneficiaries.sum(function(x) {
          return x.modifiers.offset;
        });
        totalMultiplier = line.beneficiaries.sum(function(x) {
          return x.modifiers.multiplier;
        });
        amountToDivide = totalSpentAmount - totalFixedAmount - totalOffset;
        amountForEachOne = amountToDivide / totalMultiplier;
        line.computing = {
          totalSpentAmount: totalSpentAmount,
          totalOffset: totalOffset,
          totalMultiplier: totalMultiplier,
          totalFixedAmount: totalFixedAmount,
          amountToDivide: amountToDivide,
          amountForEachOne: amountForEachOne
        };
        line.computed = {
          balance: {},
          given: {},
          spent: {}
        };
        line.beneficiaries.map(function(ben) {
          line.computed.spent[ben.name] = ben.fixedAmount ? ben.fixedAmount : amountForEachOne * ben.modifiers.multiplier + ben.modifiers.offset;
          return line.computed.given[ben.name] = 0;
        });
        line.payers.map(function(payer) {
          var _base, _name;
          line.computed.given[payer.name] = payer.amount;
          return (_base = line.computed.spent)[_name = payer.name] != null ? _base[_name] : _base[_name] = 0;
        });
        _ref = line.computed.spent;
        _fn = (function(_this) {
          return function(person) {
            return line.computed.balance[person] = line.computed.given[person] - line.computed.spent[person];
          };
        })(this);
        for (person in _ref) {
          if (!__hasProp.call(_ref, person)) continue;
          val = _ref[person];
          _fn(person);
        }
        return line;
      };

      Brain.prototype.preprocessLine = function(line) {
        var addMissingBeneficiaries, atLeastOneOffset, missingBeneficiaries, name, onlyOffsetAndFixedAmount, _i, _len;
        if (line.beneficiaries == null) {
          line.beneficiaries = line.context.people.map(function(name) {
            return {
              name: name
            };
          });
        }
        addMissingBeneficiaries = this.getOption(line, "group");
        atLeastOneOffset = line.beneficiaries.some(function(ben) {
          var _ref;
          return ((_ref = ben.modifiers) != null ? _ref.offset : void 0) != null;
        });
        onlyOffsetAndFixedAmount = line.beneficiaries.every(function(ben) {
          var _ref;
          return (ben.fixedAmount != null) || (((_ref = ben.modifiers) != null ? _ref.offset : void 0) != null);
        });
        addMissingBeneficiaries || (addMissingBeneficiaries = atLeastOneOffset && onlyOffsetAndFixedAmount);
        if (addMissingBeneficiaries) {
          missingBeneficiaries = line.context.people.filter((function(_this) {
            return function(personName) {
              return !line.beneficiaries.some(function(ben) {
                return ben.name === personName;
              });
            };
          })(this));
          for (_i = 0, _len = missingBeneficiaries.length; _i < _len; _i++) {
            name = missingBeneficiaries[_i];
            line.beneficiaries.push({
              name: name
            });
          }
        }
        return line.beneficiaries = line.beneficiaries.map(function(ben) {
          var _base, _base1;
          if (ben.modifiers == null) {
            ben.modifiers = {};
          }
          if ((_base = ben.modifiers).offset == null) {
            _base.offset = 0;
          }
          if ((_base1 = ben.modifiers).multiplier == null) {
            _base1.multiplier = ben.fixedAmount != null ? null : 1;
          }
          return ben;
        });
      };

      Brain.prototype.validateLine = function(line) {
        var alienBeneficiaries, alienPayers, alienPersons, verb;
        if (line.errors == null) {
          line.errors = [];
        }
        if (line.warnings == null) {
          line.warnings = [];
        }
        alienBeneficiaries = line.beneficiaries.filter(function(ben) {
          return !line.context.people.some(function(personName) {
            return personName === ben.name;
          });
        });
        alienPayers = line.payers.filter(function(payer) {
          return !line.context.people.some(function(personName) {
            return personName === payer.name;
          });
        });
        alienPersons = (alienBeneficiaries.concat(alienPayers)).map(function(p) {
          return p.name;
        });
        if (alienPersons.length > 0) {
          verb = alienPersons.length > 1 ? 'are' : 'is';
          return line.errors.push({
            code: "ALIEN_PERSON_ERROR",
            message: "" + (alienPersons.join(", ")) + " " + verb + " not present in the current context",
            recoverySuggestions: "you should add the missing persons with a @people command. " + ("You can edit the current people group with @people " + (alienPersons.map(function(name) {
              return "+" + name;
            }).join(" ")) + " ")
          });
        }
      };

      Brain.prototype.getOption = function(line, optionName) {
        return line.options.filter(function(x) {
          return x.name === optionName;
        })[0];
      };

      return Brain;

    })();
    if (typeof window !== "undefined" && window !== null) {
      window.GeekyWallet = new Brain;
    }
    return Brain;
  });

}).call(this);
