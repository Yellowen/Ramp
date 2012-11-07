#require '/home/lxsameer/src/ruby-amp/lib/red_amp.rb'
$LOAD_PATH.unshift(".")
require_relative 'ramp'

class Event < Ramp::Command
  arguments sender: Ramp::Fields::StringArg, name: Ramp::Fields::StringArg  
end


s = Ramp::AmpClient.new 'localhost', 3333, :async => true
s.call_remote(Event, sender: "mew", name: "somehow")

