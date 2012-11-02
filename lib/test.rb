#require '/home/lxsameer/src/ruby-amp/lib/red_amp.rb'
$LOAD_PATH.unshift(".")
require_relative 'ramp'

## $LOAD_PATH.unshift(".")
#s = Ramp::AMPClient.new 'localhost', 2222
#s.call_remote("sameer")
s = Ramp::AmpClient.new 'localhost', 3333
s.call_remote("event", :asask => 23,
              :asdas_command => "sum",
              :a => 23)
