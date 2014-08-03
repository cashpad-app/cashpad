define ['jquery', 'goog!visualization,1,packages:[corechart]'], ($) ->

  class ChartHelper

    drawTotalsChart: (totals, divId) ->
      emptyData = data = new google.visualization.DataTable
      data.addColumn 'string', 'person'
      data.addColumn 'number', 'balance'
      chart = new google.visualization.BarChart document.getElementById(divId)
      maxValue = null
      minValue = null
      for own name,total of totals
        data.addRows [[name, 0]]
        maxValue = unless maxValue >= total.balance then total.balance else maxValue
        minValue = unless minValue <= total.balance then total.balance else minValue

      options =
        height: 40 * Object.keys(totals).length + 20
        legend: 'none'
        animation:
          duration: 1000
          easing: 'out'
        hAxis:
          maxValue: maxValue
          minValue: minValue

      chart.draw data, options

     # update data only after the first draw, in order to trigger the animation

      i = 0
      for own name,total of totals
        data.setCell i, 1, total.balance
        i++

      formatter = new google.visualization.NumberFormat
        negativeColor: 'red'
      formatter.format data, 1
      chart.draw data, options
