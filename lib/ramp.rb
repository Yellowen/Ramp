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
require 'socket'
require 'stringio'

require "ramp/version"
require "ramp/command.rb"


module Ramp
  # Ramp module

  
  class AmpPacket
    # This class is responsble for packing and unpacking the AMP protocol pack

    def initialize(kwargs={})
      @_kwargs = kwargs
      @buffer = []
      self.generate_packet()
    end

    def to_s
      # Build a AMP packet data from kwargs hash for more information about
      # amp protocol structure take a look at:
      # http://www.amp-protocol.net

      @buffer.pack("c*")

    end

    def to_a
      @buffer
    end

    def split_bytes (hex)
      hex.each_char.each_slice(2).map {|x| x.join}
    end



    def self.loads(data)
      # Construct a hash from given data and return it
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


  class AmpClient
    # AmpClient class is responsble for establishing a connection to a AMPserver

    # A Class variable (static attribute) to hold the asks sequences
    @@ask_seqs = []

    def initialize (host, port, secure=false, ssl_key=nil, ssl_cert=nil)
      begin
        @socket = TCPSocket.new host, port
      rescue Errno::ECONNREFUSED
        abort("Connection Refused")
      end

    end

    def call_remote(func, kwargs)
      while 1 do
        ask = rand(999999)
        if not @@ask_seqs.include? ask
          @@ask_seqs << ask
          break
        end
      end

      kwargs = Hash[kwargs.map{|k, v|[k.to_sym, v]}]
      if kwargs.include? :_ask or kwargs.include? :_command
        raise ArgumentError, "':_ask' and ':_command' should not be in kwargs"
      end

      command_struct = {
        :_ask => ask,
        :_command => func,
      }

      command_struct.merge!(kwargs)
      packet = AmpPacket.new(command_struct)
      @socket.syswrite(packet.to_s)
      
      data = @socket.recv(1024)
      result = AmpPacket::loads(data)
      
      if result.include? :_answer
        result.delete :_answer
        result
      elsif result.include? :_error
        exception = Object.const_set(result[:_error_code], Class.new(StandardError))
        raise exception, result[:_error_descriptio]
      end
    end
    
  end
  

  class AmpServer
    def initialize (host, port, secure=false, ssl_key=nil, ssl_cert=nil)
        @socket = TCPServer.new port
    end
    
    def listen
      loop do
        c = @socket.accept
        data = c.recv(1024)
        result = AmpPacket::loads(data)
        puts "RESULT: #{result}"
        c.close()
      end
    end
  end
end
