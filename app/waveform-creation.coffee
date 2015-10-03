$ = require 'jquery'
async = require 'async'
request = require 'request'
JSFtp = require 'jsftp'


oldConsole = console.log
console.log = (args...) ->
  oldConsole.apply(this)
  $('#fake-console').prepend "<div>#{JSON.stringify(args)}</div>"


generateWaveform = (file, options={}, callback) ->
  fileReader  = new FileReader
  fileReader.onload = ->

    waveformSettings =
      waveform:
        width: options.waveformWidth || 875
        height: options.waveformHeight || 85
        color: options.waveformColor || '#F5FF00'
      bar:
        align: options.barAlign || 'center'
        width: options.barWidth || 1
        gap: options.barGapWidth || 0

    WaveformGenerator(@result, waveformSettings).then (svg) ->
      $svgContainer = $('<div class="svg-container">').attr 'data-color', waveformSettings.waveform.color
      $svgContainer[0].innerHTML = svg
      $svgContainer.appendTo 'body'
      $svgContainer.hide()
      $svg = $('svg', $svgContainer)

      img = new Image()
      img.src = "data:image/svg+xml," + encodeURIComponent(svg)

      mycanvas = document.createElement('canvas')
      mycanvas.width = $svg.width()
      mycanvas.height = $svg.height()
      ctx = mycanvas.getContext("2d")
      ctx.drawImage(img, 0, 0)
      callback mycanvas.toDataURL("image/png")

  fileReader.readAsArrayBuffer file

getLoginDetails = (type) ->
  data = {}
  $("form[name='#{type}'").serializeArray().map (x) -> data[x.name] = x.value
  localStorage.setItem "loginDetails_#{type}", JSON.stringify data
  return data

getBufferFromDataUrl = (url) ->
  base64Data = url.replace(/^data:image\/png;base64,/, "")
  base64Data += base64Data.replace('+', ' ')
  return new Buffer(base64Data, 'base64')

$(document).ready ->
  $status = $('.status-box')

  console.log "waveform creation loaded"

  for type in ['mixes', 'waveforms']
    thisDataString = localStorage["loginDetails_#{type}"]
    thisData = false
    try
      thisData = JSON.parse thisDataString
    $thisForm = $("form[name='#{type}'")
    for key, val of thisData
      $("input[name='#{key}']", $thisForm).val val

  setStatus = (status) ->
    $status.html status

  $('.config-box input').on 'change', ->
    # trigget getLoginDetails to save the local data
    getLoginDetails $(this).closest('form').attr('name')

  $('.waveform-upload').on 'change', ->
    file = this.files[0]

    newFileName = file.name.split('.')
    newFileName.pop()
    newFileName = newFileName.join('.')

    setStatus "Generating Waveforms..."

    $uploadBar = $(".upload-bar").addClass('ready')
    $backBar = $('.back-bar', $uploadBar).css("background-image", "none")
    $frontBar = $('.front-bar', $uploadBar).css("background-image", "none").css('width',"0%")

    ftpMixes = new JSFtp getLoginDetails 'mixes'
    ftpWaveforms = new JSFtp getLoginDetails 'waveforms'

    async.series [
      (done) ->
        generateWaveform file, waveformColor: "#444444", (png) ->
          $backBar.css "background-image", "url('#{png}')"
          ftpWaveforms.put getBufferFromDataUrl(png), "#{newFileName}_960_999999.png", done
      ,
      (done) ->
        generateWaveform file, {}, (png) ->
          $frontBar.css "background-image", "url('#{png}')"
          ftpWaveforms.put getBufferFromDataUrl(png), "#{newFileName}_960_F5FF00.png", done
    ] , ->

      setStatus "Uploading..."
      $frontBar.removeClass 'complete'
      outputFile = "http://#{ftpMixes.host}/#{file.name}"
      completedDownload = false
      do uploadInterval = ->
        unless completedDownload
          request.head outputFile, (err,res) ->
            unless completedDownload
              size = Math.round(((res.headers['content-length']/file.size) || 0) * 100) + "%"
              setStatus "Uploading... #{size}"
              $frontBar.css 'width', size
              setTimeout uploadInterval, 1000 * 3

      # TODO first delete the old one
      ftpMixes.put file.path, file.name, (err, res) ->
        completedDownload = true
        $frontBar.addClass('complete').css 'width', "100%"
        setStatus "Completed upload of <b>#{outputFile}</b>"
