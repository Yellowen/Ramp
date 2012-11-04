$LOAD_PATH.unshift(".")
require_relative 'ramp'

class Event < Ramp::Command
  name= "sameer"
  arguments sender: nil, kwargs: {"key" => "value"}
end

a = Event.new

puts a.name
