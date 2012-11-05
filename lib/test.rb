#require '/home/lxsameer/src/ruby-amp/lib/red_amp.rb'
$LOAD_PATH.unshift(".")
require_relative 'ramp'

class Event < Ramp::Command
  arguments sender: Ramp::Fields::StringArg, name: Ramp::Fields::StringArg
  
end

a = Event.new sender: "me", name: "someevent"
puts a.values, a.to_s

s = Ramp::AmpClient.new 'localhost', 3333
s.call_remote(a)

