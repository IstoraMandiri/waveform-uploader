JSFtp = require 'jsftp'

window.ftpMixes = new JSFtp
  host: '***'
  user: '***'
  pass: '***'

window.ftpWaveforms = new JSFtp
  host: '***'
  user: '***'
  pass: '***'


# ftpMixes.ls ".", (err, res) ->
#   res.forEach (file) ->
#     console.log(file.name)

# ftpWaveforms.ls ".", (err, res) ->
#   res.forEach (file) ->
#     console.log(file.name)
