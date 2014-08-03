define ->
  Array::sum = (fn = (x) -> x) ->
    @reduce ((a, b) -> a + fn b), 0

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
      computing = {}
      computing.totalSpentAmount = line.payers.sum (x) -> x.amount
      computing.totalFixedAmount = line.beneficiaries.sum (x) -> x.fixedAmount
      computing.totalOffset = line.beneficiaries.sum (x) -> x.offset
      computing.totalMultiply =line.beneficiaries.sum (x) -> x.multiply 
      # save intermediate computation in line
      line.computing = computing
      # return line object
      line

    preprocessLine: (line) => 
      # add beneficiaries from context if none is defined
      unless line.beneficiaries?
        line.beneficiaries = line.context.people.map (name) -> {name: name}
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

