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

require "ramp/version"
require "ramp/command.rb"
require "ramp/fields.rb"


module Ramp
  # Ramp module

  class AmpClient
    # AmpClient class is responsble for establishing a connection to a AMPserver

    @@sent_packets = Hash.new

    def initialize (host, port, secure=false, ssl_key=nil, ssl_cert=nil)
      begin
        @socket = TCPSocket.new host, port
      rescue Errno::ECONNREFUSED
        abort("Connection Refused")
      end

    end

    def call_remote(command, kwargs)

      # Create a new command instance
      obj = command.new kwargs

      # Add the curretn command instance to the sent hash
      @@sent_packets[obj.ask] = obj

      # send the encoded data across the net
      @socket.syswrite(obj.to_s)
      

      data = @socket.recv(1024)
      result = command::loads(data)
      
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
