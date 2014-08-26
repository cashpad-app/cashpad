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

    parseAndCompute: (textInput) =>
      parsed = parser.parse(textInput)
      @computeFromParsed(parsed)

    computeFromParsed: (parsed) =>
      @flatListOfLines = @getFlatListOfLines(parsed.group.lines, parsed.group.context)
      @computed = @flatListOfLines.map (line) => @computeLine(line)
      @computed

    # get errors by line, to be called after computeFromParsed
    getErrors: => @errors || {}

    # flatten context into each line
    # TODO take care of abbreviations
    getFlatListOfLines: (lines, context) =>
      lines.reduce ((flatList, line) =>
        if line.group? # line is actually a group...
          nestedFlatList = @getFlatListOfLines(line.group.lines, @mergeContext(context, line.group.context, line.group.line))
          flatList = flatList.concat nestedFlatList
        else
          line.context = {}
          line.context.people = context.people
          flatList.push line
        flatList
      ), []

    # merge context for nexted groups
    mergeContext: (parentContext, childContext, lineNumber) ->
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
                @addError('PERSON_ADDED_ALREADY_IN_CONTEXT_WARNING', lineNumber, null, {name: person.name})
              else
                context.people.push person.name
            else if person.mod == '-'
              if parentContext.people.some((name) => name == person.name)
                context.people = context.people.filter (name) => name != person.name
              else
                @addError('PERSON_REMOVED_NOT_IN_CONTEXT_WARNING', lineNumber, null, {name: person.name})
      context



    # compute balance, spent and given for each line
    computeLine: (line) =>
      # preprocessing tasks..
      @preprocessLine(line)
      # validation tasks..
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
      # validation and proportional split ($)
      bensTotalSpentAmount = 0
      for own person, val of line.computed.spent
        do => bensTotalSpentAmount += val
      if bensTotalSpentAmount != totalSpentAmount
        if @getOption(line, "splitProportionally")
          toDistribute = totalSpentAmount - bensTotalSpentAmount
          for own person, val of line.computed.spent
            do => line.computed.spent[person] += val / bensTotalSpentAmount * toDistribute
        else
          @addError("PAYED_AMOUNT_NOT_MATCHING_ERROR", line.line, line)
      # compute balance
      for own person, val of line.computed.spent
        do (person) =>
          line.computed.balance[person] = line.computed.given[person] - line.computed.spent[person]
      # return line object
      line

    preprocessLine: (line) =>
      # complete payers' and bens' names if abbreviated using current context
      abbreviations = @abbrev line.context.people
      payer.name = abbreviations[payer.name] || payer.name for payer in line.payers
      if line.beneficiaries?
        ben.name = abbreviations[ben.name] || ben.name for ben in line.beneficiaries
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
      line.errors ?= []
      line.warnings ?= []
      # throw an error if a non existing beneficiary or payer is found
      alienBeneficiaries = line.beneficiaries.filter (ben) ->
        not line.context.people.some (personName) -> personName == ben.name
      alienPayers = line.payers.filter (payer) ->
        not line.context.people.some (personName) -> personName == payer.name
      alienPersons = (alienBeneficiaries.concat alienPayers).map (p) -> p.name
      if alienPersons.length > 0
        @addError("ALIEN_PERSON_ERROR", line.line, line, {alienPersons: alienPersons})

    getOption: (line, optionName) =>
      line.options.filter((x) -> x.name == optionName)[0]

    abbrev: (list) =>
      # sort them lexicographically, so that they're next to their nearest kin
      list = list.sort (a, b) -> (a.localeCompare b)

      # walk through each, seeing how much it has in common with the next and previous
      abbrevs = {}
      prev = ""
      i = 0
      l = list.length

      while i < l
        current = list[i]
        next = list[i + 1] or ""
        nextMatches = true
        prevMatches = true
        continue  if current is next
        j = 0
        cl = current.length

        while j < cl
          curChar = current.charAt(j)
          nextMatches = nextMatches and curChar is next.charAt(j)
          prevMatches = prevMatches and curChar is prev.charAt(j)
          if not nextMatches and not prevMatches
            j++
            break
          j++
        prev = current
        if j is cl
          abbrevs[current] = current
          continue
        a = current.substr(0, j)

        while j <= cl
          abbrevs[a] = current
          a += current.charAt(j)
          j++
        i++
      abbrevs

    addError: (code, lineNumber, lineObject=null, options={}) =>
      pluralize = (list, singular, plural) -> if list.length > 1 then plural else singular
      @errors ?= {}
      @errors[lineNumber] ?= []
      e = switch code

        when "ALIEN_PERSON_ERROR"
          verb = pluralize(options.alienPersons, 'is', 'are')
          message: "#{options.alienPersons.join(", ")} #{verb} not present in the current context"
          recoverySuggestions: "you should add the missing persons with a @people command. " +
            "You can edit the current people group with @people #{options.alienPersons.map((name) -> "+#{name}").join(" ")} "

        when "PAYED_AMOUNT_NOT_MATCHING_ERROR"
          message: "total spent amunt computed doesn't sum up to what was spent"
          recoverySuggestions: "either edit the spent amounts or distribute the remainder among" +
            "others in the current people group using '...'. If you forgot taxes or tip use '$'"

        when "PERSON_ADDED_ALREADY_IN_CONTEXT_WARNING"
          message: "you added #{options.name} but it was already present"
          recoverySuggestions: "remove +#{options.name} from the @people declaration"

        when "PERSON_REMOVED_NOT_IN_CONTEXT_WARNING"
          message: "you removed #{options.name} but it was not present"
          recoverySuggestions: "remove -#{options.name} from the @people declaration"

      e.code = code
      e.type = if ~code.indexOf "ERROR"
        "error"
      else if ~code.indexOf "WARNING"
        "warning"

      if lineObject?
        lineObject.errors.push e
      @errors[lineNumber].push e

