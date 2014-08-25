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
      @flatListOfLines = @getFlatListOfLines(parsed.group.lines, parsed.group.context)
      @computed = @flatListOfLines.map (line) => @computeLine(line)
      @computed

    # flatten context into each line
    # TODO take care of abbreviations
    getFlatListOfLines: (lines, context) =>
      lines.reduce ((flatList, line) =>
        if line.group? # line is actually a group...
          nestedFlatList = @getFlatListOfLines(line.group.lines, @mergeContext(context, line.group.context))
          flatList = flatList.concat nestedFlatList
        else
          line.context = {}
          line.context.people = context.people
          flatList.push line
        flatList
      ), []

    # merge context for nexted groups
    mergeContext: (parentContext, childContext) ->
      context = {}
      # merge people
      if childContext.people?
        context.people = childContext.people
      else if childContext.people_delta?
        context.people = [].concat parentContext.people # makes copy of list
        for person in childContext.people_delta
          do =>
            if person.mod == '+'
              if parentContext.people.some((name) => name == person.name)
                # todo generate warning
              else
                context.people.push person.name
            else if person.mod == '-'
              if parentContext.people.some((name) => name == person.name)
                context.people = context.people.filter (name) => name != person.name
              else
                # todo generate warning
      context



    # compute balance, spent and given for each line
    computeLine: (line) =>
      # preprocessing tasks..
      @preprocessLine(line)
      #validation tasks..
      @validateLine(line)
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

    validateLine: (line) =>
      line.errors = line.errors || []
      # throw an error if a non existing beneficiary or payer is found
      alienBeneficiaries = line.beneficiaries.filter (ben) ->
        not line.context.people.some (personName) -> personName == ben.name
      alienPayers = line.payers.filter (payer) ->
        not line.context.people.some (personName) -> personName == payer.name
      alienPersons = (alienBeneficiaries.concat alienPayers).map (p) -> p.name
      if alienPersons.length > 0
        line.errors.push('#{alienPersons.join(", ")} are not present in the current context')

    getOption: (line, optionName) =>
      line.options.filter((x) -> x.name == optionName)[0]


