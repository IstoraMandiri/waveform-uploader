$ = require 'jquery'
waveform = require 'waveform'
fs = require 'fs'

generateForm = (file, options={}) ->
  waveform file,
    'png': "-"
    'png-width': 960 * 2
    'png-height': 75
    'png-color-bg': '000000ff'
    'png-color-center': options.center || 'F5FF00ff'
    'png-color-outer': options.outer || '454700ff'
  , (err, buf) ->
    $('<img>')
    .attr("src", "data:image/jpeg;charset=utf-8;base64," + buf.toString('base64'))
    .appendTo('body')

$(document).ready ->
  $('.waveform-upload').on 'change', ->
    file = this.files[0]

    $status = $('.status')
    .text "converting..."
    # async, when both doe
    generateForm file.path,
      outer: 'F5FF00ff'
      center: 'FCFFB2ff'
      filename: file.name.replace('.mp3', "") + "_960_F5FF00.png"

    generateForm file.path,
      center: '333333ff'
      outer: '555555ff'
      filename: file.name.replace('.mp3', "") + "_960_999999.png"

    # when both are done, then add a buttono
    # approve and start upload
    # uploading mp3 ....

    # here are the links!