define ->

  Array::sum = (fn = (x) -> x) ->
    @reduce ((a, b) ->
      elem = fn(b) || 0
      a + elem
    ), 0

  if not Array.prototype.some
    Array.prototype.some = (f) -> (x for x in @ when f(x)).length > 0

  if not Array.prototype.every
    Array.prototype.every = (f) -> (x for x in @ when f(x)).length == @length

  class Brain

    computeFromParsed: (parsed) =>
      @flatListOfLines = @getFlatListOfLines(parsed.group)
      @computed = @flatListOfLines.map (line) => @computeLine(line)
      @computed

    # flatten context into each line
    # TODO take care of abbreviations
    getFlatListOfLines: (group) =>
      group.lines.map (line) ->
        if line.context? # line is actually a group...
          console.log "TODO manage nested context"
        else
          line.context = {}
          line.context.people = group.context.people
        line

    # compute balance, spent and given for each line
    computeLine: (line) =>
      # preprocessing tasks..
      @preprocessLine(line)
      # intermediate computation steps
      totalSpentAmount = line.payers.sum (x) -> x.amount
      totalFixedAmount = line.beneficiaries.sum (x) -> x.fixedAmount
      totalOffset = line.beneficiaries.sum (x) -> x.modifiers.offset
      totalMultiplier = line.beneficiaries.sum (x) -> x.modifiers.multiplier
      amountToDivide = totalSpentAmount - totalFixedAmount - totalOffset
      amountForEachOne = amountToDivide / totalMultiplier
      line.computing =
        totalSpentAmount: totalSpentAmount
        totalOffset: totalOffset
        totalMultiplier: totalMultiplier
        totalFixedAmount: totalFixedAmount
        amountToDivide: amountToDivide
        amountForEachOne: amountForEachOne
      # compute balance
      line.computed =
        balance: {}
        given: {}
        spent: {}
      line.beneficiaries.map (ben) ->
        # spent
        line.computed.spent[ben.name] = if ben.fixedAmount
          ben.fixedAmount
        else
          amountForEachOne * ben.modifiers.multiplier + ben.modifiers.offset
        # set given to 0 as default for beneficiaries
        line.computed.given[ben.name] = 0
      # given
      line.payers.map (payer) ->
        line.computed.given[payer.name] = payer.amount
        line.computed.spent[payer.name] ?= 0
      # compute balance
      for own person, val of line.computed.spent 
        do (person) => 
          line.computed.balance[person] = line.computed.given[person] - line.computed.spent[person]
      # return line object
      line

    preprocessLine: (line) =>
      # add beneficiaries from context if none is defined
      unless line.beneficiaries?
        line.beneficiaries = line.context.people.map (name) -> {name: name}
      # add remaining beneficiaries if option group is present ...
      addMissingBeneficiaries = @getOption(line, "group")
      # ... or if there are only offset and fixedamount and at least one offset
      atLeastOneOffset = line.beneficiaries.some (ben) -> ben.modifiers?.offset? 
      onlyOffsetAndFixedAmount = line.beneficiaries.every (ben) -> 
        ben.fixedAmount? || ben.modifiers?.offset?
      addMissingBeneficiaries ||= atLeastOneOffset and onlyOffsetAndFixedAmount
      if addMissingBeneficiaries
        missingBeneficiaries = line.context.people.filter (personName) =>
          not line.beneficiaries.some (ben) -> ben.name == personName
        line.beneficiaries.push {name: name} for name in missingBeneficiaries
      # set defaults for offset and multiplier
      line.beneficiaries = line.beneficiaries.map (ben) ->
        ben.modifiers ?= {}
        ben.modifiers.offset ?= 0
        ben.modifiers.multiplier ?= if ben.fixedAmount? then null else 1
        ben

    getOption: (line, optionName) =>
      line.options.filter((x) -> x.name == optionName)[0]


