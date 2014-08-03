define (require) ->
  Brain = require('geekywalletlib')
  $(document).ready () ->
    $('#run1').click () ->
      rawInputString = $('#rawInput').val()
      brain = new Brain
      parsed = parser.parse(rawInputString)
      console.log "parsed", parsed
      flattenList = brain.computeFromParsed parsed
      console.log "flattenList", flattenList

