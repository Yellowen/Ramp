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

    def generate_packet()
      @_kwargs.each do |key, value|

        if key.length > 255
          raise AmpAskPacket::KeyLenError, "AMP keys should have 255 byte max kength"
        end
        
        [0, key.length].each {|x| @buffer << x}
        key.to_s.bytes.to_a.each {|x| @buffer << x}

        value_lenght = self.split_bytes "%04x" % value.to_s.length.to_s(16)
        @buffer << value_lenght[0].to_i
        @buffer << value_lenght[1].to_i
        
        value.to_s.bytes.to_a.each {|x| @buffer << x}
        
      end

      [0x00, 0x00].each {|x| @buffer << x}

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
      puts kwargs, command_struct, ask
      #print ">>> ", packet.to_a, packet.to_s, "\n"
      @socket.puts(packet.to_s)
    end
    
  end

end
