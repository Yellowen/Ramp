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

    def initialize (host, port, kwargs={secure: false,
                      ssl_key: nil,
                      ssl_cert:nil,
                      async: false})

      @async = kwargs[:async]
      @secure = kwargs[:secure]
      @ssl_key = kwargs[:ssl_key]
      @ssl_cert = kwargs[:ssl_cert]

      @host = host
      @port = port

      make_connection
      
    end

    def call_remote(command, kwargs)

      # Create a new command instance
      obj = command.new kwargs

      # Add the curretn command instance to the sent hash
      @@sent_packets[obj.ask] = obj

      if @async
        t = Thread.new {
          transfer obj.to_s
        }
        t.abort_on_exception = true
        t.run
      else
        transfer obj.to_s
      end
      puts "transfer done"

    end

    # Private members -----------------------------------
    private
    
    def make_connection 
      begin
        @socket = TCPSocket.new @host, @port
      rescue Errno::ECONNREFUSED
        abort("Connection Refused")
      end
    end

    def transfer data
      # send the encoded data across the net
      @socket.syswrite(data)

      # TODO: Should i specify a recieving limitation ?
      rawdata = @socket.recv(1024)
      
      data = Command::loads(rawdata)
      
      if data.include? :_answer
        if @@sent_packets.keys.include? data
          @@sent_packets[data[:_answer]].callback(data)
        end
      elsif data.include? :_error
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
        result = Command::loads(data)
        puts "RESULT: #{result}"
        sleep(10)
        puts "wake up"
        #c.syswrite(data)
        c.close()
      end
    end
  end
end
