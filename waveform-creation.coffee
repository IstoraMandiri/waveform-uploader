$ = require 'jquery'
waveform = require 'waveform'

$(document).ready ->
  $('.waveform-upload').on 'change', ->
    waveform this.files[0].path,
      'png': "-"
    , (err, buf) ->
      $('<img>')
      .attr("src", "data:image/jpeg;charset=utf-8;base64," + buf.toString('base64'))
      .appendTo('body')


