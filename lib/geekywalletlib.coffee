define ->

  Array::sum = (fn = (x) -> x) ->
    @reduce ((a, b) -> a + fn b), 0

  Array::hasElementMatching = (fn = (x) -> x) ->
    filtered = @filter ((item, i) -> fn item)
    filtered.length > 0

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
      totalOffset = line.beneficiaries.sum (x) -> x.offset
      totalMultiply = line.beneficiaries.sum (x) -> x.multiply
      amountToDivide = totalSpentAmount - totalFixedAmount - totalOffset
      amountForEachOne = amountToDivide / totalMultiply
      line.computing =
        totalSpentAmount: totalSpentAmount
        totalOffset: totalOffset
        totalMultiply: totalMultiply
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
          amountForEachOne * ben.multiply + ben.offset
        # set given to 0 as default for beneficiaries
        line.computed.given[ben.name] = 0
      # given
      line.payers.map (payer) ->
        line.computed.given[payer.name] = payer.amount
      # compute balance
      line.beneficiaries.map (ben) ->
        line.computed.balance[ben.name] = line.computed.given[ben.name] - line.computed.spent[ben.name]

      # return line object
      line

    preprocessLine: (line) =>
      # add beneficiaries from context if none is defined
      unless line.beneficiaries?
        line.beneficiaries = line.context.people.map (name) -> {name: name}
      # add remaining beneficiaries if option "group" is present
      if @getOption(line, "group")
        missingBeneficiaries = line.context.people.filter (personName) =>
          not line.beneficiaries.hasElementMatching (ben) -> ben.name == personName
        line.beneficiaries.push {name: name} for name in missingBeneficiaries
      # compute fixed amount, offset and multiply
      line.beneficiaries = line.beneficiaries.map (ben) ->
        ben.fixedAmount = null
        ben.offset = 0
        ben.multiply = 1
        if ben.amount?
          if ben.modifier?
            ben.offset = ben.amount if ben.modifier == '+'
            ben.offset = -ben.amount if ben.modifier == '-'
            ben.multiply = ben.amount if ben.modifier == '*'
          else
            ben.fixedAmount = ben.amount
            ben.multiply = null
            ben.offset = null
        ben

    getOption: (line, optionName) =>
      line.options.filter((x) -> x.name == optionName)[0]


