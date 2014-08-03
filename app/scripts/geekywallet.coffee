define (require) ->
  Brain = require('geekywalletlib')
  parser = require('syntax/parser')
  require ['jquery'], ($) ->
    $(document).ready () ->
      $('#run').click () ->
        rawInputString = $('#rawInput').val()
        brain = new Brain
        parsed = parser.parse(rawInputString)
        # console.log "parsed", parsed
        lines = brain.computeFromParsed parsed
        console.log "lines", lines

        accumulateValue = (acc, line, value) ->
          for own name,bal of line.computed[value]
            unless acc[name]?
              acc[name] = {}
            unless acc[name][value]?
              acc[name][value] = 0
            acc[name][value] += bal
          acc

        totals = lines.reduce (acc, line) ->
          accumulateValue(acc, line, 'balance')
          accumulateValue(acc, line, 'spent')
          accumulateValue(acc, line, 'given')
        , {}


        $('#totals').empty()
        $('#partials').empty()

        for line in lines
          do (line) ->
            lineTitle = $('<h4>' + line.desc + '</h4>')
            lineTable = $('<table></table>')
              .addClass('table')
              .addClass('table-striped')

            lineTable.append(
              '<thead>' +
                '<tr>' +
                  '<td>name</td>' +
                  '<td>spent</td>' +
                  '<td>given</td>' +
                  '<td>balance</td>' +
                '</tr>' +
              '</thead>')
            for ben in line.beneficiaries
              do (ben) ->
                lineTable.append(
                  '<tr>' +
                    '<td>' + ben.name + '</td>' +
                    '<td>' + line.computed.spent[ben.name] + '</td>' +
                    '<td>' + line.computed.given[ben.name] + '</td>' +
                    '<td>' + line.computed.balance[ben.name] + '</td>' +
                  '</tr>')
            $("#partials").append(lineTitle)
            $("#partials").append(lineTable)

        $('#totals').append(
          '<thead>' +
            '<tr>' +
              '<td>name</td>' +
              '<td>spent</td>' +
              '<td>given</td>' +
              '<td>balance</td>' +
            '</tr>' +
          '</thead>')

        for own name,total of totals
          $('#totals').append(
            '<tr>' +
              '<td>' + name + '</td>' +
              '<td>' + total.spent + '</td>' +
              '<td>' + total.given + '</td>' +
              '<td>' + total.balance + '</td>' +
            '</tr>')
