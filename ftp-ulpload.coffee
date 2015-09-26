FTPS = require 'ftps'

ftps = new FTPS
  host: 'domain.com' # required
  username: 'Test' # required
  password: 'Test' # required
  protocol: 'sftp' # optional, values : 'ftp', 'sftp', 'ftps',... default is 'ftp'
  port: 22 # optional

