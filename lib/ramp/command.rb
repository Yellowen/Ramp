# -----------------------------------------------------------------------------
#    RAMP - AMP protocol client implementation in Ruby
#    Copyright (C) 2012 Yellowen
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
# -----------------------------------------------------------------------------

module Ramp

  class Command
    
    def initialize (args)
      # Initialize an object with provided values for fields defined in
      # @arguments using argument class method
      @values = Hash.new
      @buffer = []
      args.each do |key, value|

        if not @arguments.include? key
          raise ArgumentError, "'#{key}' is not defined in '#{self.class}'."
        end

        @value[keu.to_sym] = @argument[key.to_sym].new value
      end
    end

    def self.arguments args
      @arguments = args
    end

    def self.responses args
      @responses = args
    end

    def to_s
      @buffer.pack("c*")      
    end

    def generate_packet()
      @values.each do |key, value|

        if key.length > 255
          raise KeyLenError, "AMP keys should have 255 byte max kength"
        end
        
        [0, key.to_s.bytes.to_a.length].each {|x| @buffer << x}
        key.to_s.bytes.to_a.each {|x| @buffer << x}

        value_lenght = self.split_bytes "%04x" % value.to_s.bytes.to_a.length.to_s(16)
        @buffer << value_lenght[0].to_i
        @buffer << value_lenght[1].to_i
        
        
        value.to_s.bytes.to_a.each {|x| @buffer << x}
      end

      [0x00, 0x00].each {|x| @buffer << x}
    end

    class KeyLenError < StandardError
    end

  end
end
