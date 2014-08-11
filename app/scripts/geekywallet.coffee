define (require) ->
  Brain = require('geekywalletlib')
  parser = require('syntax/parser')
  require ['jquery'], ($) ->
    $(document).ready () ->
      $('#run').click () ->
        try
          rawInputString = $('#rawInput').val()
          brain = new Brain
          parsed = parser.parse(rawInputString)
          lines = brain.computeFromParsed parsed
          console.debug "lines", lines

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
                .addClass('table-condensed')
                .addClass('table-hover')

              lineTable.append(
                '<thead>' +
                  '<tr>' +
                    '<th>name</th>' +
                    '<th>spent</th>' +
                    '<th>given</th>' +
                    '<th>balance</th>' +
                  '</tr>' +
                '</thead>')
              for ben in line.beneficiaries
                do (ben) ->
                  lineTable.append(
                    '<tr>' +
                      '<td>' + ben.name + '</td>' +
                      '<td>' + line.computed.spent[ben.name].toFixed(2) + '</td>' +
                      '<td>' + line.computed.given[ben.name].toFixed(2) + '</td>' +
                      '<td>' + line.computed.balance[ben.name].toFixed(2) + '</td>' +
                    '</tr>')
              $("#partials").append(lineTitle)
              $("#partials").append(lineTable)

          $('#totals').append(
            '<thead>' +
              '<tr>' +
                '<th>name</th>' +
                '<th>spent</th>' +
                '<th>given</th>' +
                '<th>balance</th>' +
              '</tr>' +
            '</thead>')

          for own name,total of totals
            $('#totals').append(
              '<tr>' +
                '<td>' + name + '</td>' +
                '<td>' + total.spent.toFixed(2) + '</td>' +
                '<td>' + total.given.toFixed(2) + '</td>' +
                '<td>' + total.balance.toFixed(2) + '</td>' +
              '</tr>')

           ChartHelper = require('charts')
           chartHelper = new ChartHelper
           chartHelper.drawTotalsChart totals, 'totalsChart'
        catch e
          console.error "line " + e.line + " col " + e.column + "\n" + e.message
