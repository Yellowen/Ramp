$LOAD_PATH.unshift(".")
require_relative 'ramp'

## $LOAD_PATH.unshift(".")
#s = Ramp::AMPClient.new 'localhost', 2222
#s.call_remote("sameer")
s = Ramp::AmpServer.new 'localhost', 3333
s.listen

