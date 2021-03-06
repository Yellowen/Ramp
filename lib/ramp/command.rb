#--
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
# ++

module Ramp

  #Base class for an AMP protocol command. Any user command should subclassed
  #from this class and define a command name, arguments, reponses and any
  #exceptions or callback method if needed.
  class Command

    # EignClass -------------------------------------
    class << self
      
      attr_accessor :arguments_hash, :responses_hash, :command_name

      # Define the command name. Remote server will recognize this command this 
      # this name.
      # name:: Command name
      def command name
        @command_name = name
      end

      # Defines all the arguments of the command. arguments should define
      # in a hash and each one value should be a class that have both 
      # *to_s* instance method and *to_o* class method.
      # args:: is the hash that contains the arguments defination
      def arguments args
        @arguments_hash = args
      end

      # Defines all the possible responses of the command. Responses should
      # define in a hash and each one value should be a class that have both 
      # *to_s* instance method and *to_o* class method.
      # args:: is the hash that contains the reponses defination      
      def responses args
        @responses_hash = args
      end

      # Construct a hash from given data and return it. data should be a packed
      # amp packet.
      def loads(data)

        buffer = data.to_s.bytes.to_a
        pos = 0
        result = {}

        while 1 do

          # Parse the next key length
          key_length = 0
          buffer[pos..pos + 1].each {|x| key_length += x}

          if key_length > 255
            raise TypeError, "malform packet."
          end

          if key_length == 0
            # key length of 0 means end of package.
            break
          end

          pos += 2
          # Read the key 
          key = buffer[pos..pos + key_length - 1].pack("c*")
        
          # Parse next value length
          pos += key_length
          value_length = 0
          buffer[pos..pos + 1].each {|x| value_length += x}

          # Read the value
          pos += 2
          value = buffer[pos..pos + value_length - 1].pack("c*")
          pos += value_length
          result[key.to_sym] = value

        end
      
        result
      end
    end

    # Public -------------------------------------

    # A Class variable (static attribute) to hold the asks sequences
    @@ask_seqs = []

    attr_reader :values
    
    # Inizilize a new command using the *args* parameter, The *args* parameter
    # should conatain the exact keys as the hash that specify in *arguments*
    def initialize (args)
      # Initialize an object with provided values for fields defined in
      # @arguments using argument class method
      @values = {}
      @buffer = []
      
      @_args = args

      kwargs = Hash[args.map{|k, v|[k.to_sym, v]}]
      if kwargs.include? :_ask or kwargs.include? :_command
        raise ArgumentError, "':_ask' and ':_command' should not be in arguments"
      end

      kwargs.each do |key, value|

        # Check for key validation
        if not self.class.arguments_hash.include? key
          raise ArgumentError, "'#{key}' is not defined in '#{self.class}'."
        end


        # Construct the values ivar
        @values[key.to_sym] = self.class.arguments_hash[key.to_sym].new value
      end

      # Build a AMP packet data from kwargs hash for more information about
      # amp protocol structure take a look at:
      # http://www.amp-protocol.net
 
      @values[:_command] = self.class.command_name

      while 1 do
        # TODO: is it safe in logic ?
        ask = rand(999999)
        if not @@ask_seqs.include? ask
          @@ask_seqs << ask
          break
        end
      end
      
      @values[:_ask] = ask
      # Generate the packet data and store it into @buffer
      generate_packet
       
    end


    def to_s
     
      @buffer.pack("c*")      
    end

    def to_a
      @buffer
    end

    # Return the current command *_ask* value
    def ask
      @values[:_ask]
    end

    # Duplicat the current command with new *_ask* value
    def dup
      self.class.new @_args
    end

    # Each subclass may override this method to have a callback
    # when any answer recieved.
    def callback (*)
      nil
    end

    # Exceptions ------------------------------------------------

    class KeyLenError < StandardError
    end

    private
    # Private definations ---------------------------------------
    def split_bytes (hex)
      hex.each_char.each_slice(2).map {|x| x.join}
    end

    def generate_packet()
      @values.each do |key, value|

        if key.length > 255
          raise KeyLenError, "AMP keys should have 255 byte max kength"
        end
        
        [0, key.to_s.bytes.to_a.length].each {|x| @buffer << x}
        key.to_s.bytes.to_a.each {|x| @buffer << x}

        value_lenght = split_bytes "%04x" % value.to_s.bytes.to_a.length.to_s(16)
        @buffer << value_lenght[0].to_i
        @buffer << value_lenght[1].to_i
        
        
        value.to_s.bytes.to_a.each {|x| @buffer << x}
      end

      [0x00, 0x00].each {|x| @buffer << x}
    end 

  end
end
