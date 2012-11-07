$LOAD_PATH.unshift(".")
require_relative 'ramp'

s = Ramp::AmpServer.new 'localhost', 3333
s.listen

