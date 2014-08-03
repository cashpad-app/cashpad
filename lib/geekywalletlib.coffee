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
      line.computing =
        totalSpentAmount: line.payers.sum (x) -> x.amount
        totalFixedAmount: line.beneficiaries.sum (x) -> x.fixedAmount
        totalOffset: line.beneficiaries.sum (x) -> x.offset
        totalMultiply:line.beneficiaries.sum (x) -> x.multiply
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
        ben.fixedAmount = 0
        ben.offset = 0
        ben.multiply = 1
        if ben.amount?
          if ben.modifier?
            ben.offset = ben.amount if ben.modifier == '+'
            ben.offset = -ben.amount if ben.modifier == '-'
            ben.multiply = ben.amount if ben.modifier == '*'
          else
            ben.fixedAmount = ben.amount
        ben

    getOption: (line, optionName) =>
      line.options.filter((x) -> x.name == optionName)[0]


