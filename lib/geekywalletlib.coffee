class Brain

  computeFromParsed: (parsed) =>
    @flatListOfLines = @getFlatListOfLines(parsed.group)
    @computed = @flatListOfLines.map (line) => @computeLine(line)
    @computed

  # flatten context into each line
  # TODO take care of abbreviations
  getFlatListOfLines: (group) =>
    _.map group.lines, (line) ->
      if line.context? # line is actually a group...
        console.log "TODO manage nested context"
      else  
        line.context = {}
        line.context.people = group.context.people
      line

  # compute balance, spent and given for each line
  computeLine: (line) =>
    line
    
