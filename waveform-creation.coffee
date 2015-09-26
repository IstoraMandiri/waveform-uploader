$ = require 'jquery'
waveform = require 'waveform'
fs = require 'fs'
async = require 'async'
request = require 'request'

# make a /tmp/waveforms/ folder
tempFolder = '/tmp/waveforms'
bgPath = tempFolder + "/bg.png"
fgPath = tempFolder + "/fg.png"

clearTemp = ->
  try fs.mkdirSync '/tmp'
  try fs.mkdirSync tempFolder

  for file in fs.readdirSync tempFolder
    fs.unlinkSync "#{tempFolder}/#{file}"

generateWaveform = (file, options={}, callback) ->
  console.log file, options
  waveform file,
    'png': options.fileName || "-"
    'png-width': 960 * 2 # hack to make it look nicer
    'png-height': 75
    'png-color-bg': '000000ff'
    'png-color-center': options.center || 'F5FF00ff'
    'png-color-outer': options.outer || '454700ff'
  , callback

$(document).ready ->
  $status = $('.status-box')

  setStatus = (status) ->
    $status.html status

  $('.waveform-upload').on 'change', ->
    file = this.files[0]
    newFileName = file.name.split('.')
    newFileName.pop()
    newFileName = newFileName.join('.')

    setStatus "converting..."
    clearTemp()
    # use async to complete the following in sequence

    $uploadBar = $(".upload-bar").addClass('ready')
    $backBar = $('.back-bar', $uploadBar).css("background-image", "none")
    $frontBar = $('.front-bar', $uploadBar).css("background-image", "none").css('width',"0%")

    async.parallel [
      (done) ->
        generateWaveform file.path,
          center: '333333ff'
          outer: '555555ff'
          fileName: bgPath
        , done
      ,
      (done) ->
        generateWaveform file.path,
          outer: 'F5FF00ff'
          center: 'FCFFB2ff'
          fileName: fgPath
        , done
    ] , ->

      async.series [
        (done) ->
          ftpWaveforms.put bgPath, newFileName + "_960_999999.png", ->
            $backBar.css "background-image", "url(#{bgPath}?c=#{new Date().getTime()})"
            done()
        ,
        (done) ->
          ftpWaveforms.put fgPath, newFileName + "_960_F5FF00.png", ->
            $frontBar.css "background-image", "url(#{fgPath}?c=#{new Date().getTime()})"
            done()
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
                setTimeout uploadInterval, 1000 * 2

        ftpMixes.put file.path, file.name, (err, res) ->
          completedDownload = true
          $frontBar.addClass('complete').css 'width', "100%"
          setStatus "Completed upload of <b>#{outputFile}</b>"
