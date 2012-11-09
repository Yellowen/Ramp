#:title: Ramp Documentation
#= Ramp
#Ramp is AMP protocol implementation in Ruby language. AMP is a very
#simple message passing and RPC protocol. for more information take a
#look at {here}[http://amp-protocol.net].
#
#== Installation
#As you may know already installing ruby gems it quite easy:
# $ gem install ramp
#Isn't it easy ?
#
#== Usage
#As every thing else about Ramp, its usage is easy too :P
#At first you should be familiar with {AMP protocol}[http://amp-protocol.net]
#a little, AMP protocol usa <b>Commands</b> as its RPC units and you should
#define your own <b>Command</b> subclass. Let see an example:
#
# require 'ramp'
#
# class Event < Ramp::Command
#
#   command "Events"
#
#   arguments (
#              {name: Ramp::Fields::StringField,
#               sender: Ramp::Fields::StringField,
#               kwargs: Ramp::Fields::JsonField}
#              )
#
#   responses (
#              {status: Ramp::Fields::IntegerField}
#              )
#
# end
#
#Ok, let's talk a bit more about the example class. As your can see the 
#<i>Event</i> class is a subclass of <b>Ramp::Command</b> class. and we 
#specify a command for our class by using <b>command</b> class method.
#Also you should specify the command arguments and responses like above.
#
#That is all we need, now we can run the remote command easily like:
#
# requre 'ramp'
# 
# rempte = Ramp::AmpClient.new 'localhost', 8888, :async => false
# remote.call_remote(Event, sender: "me", name: "something", kwargs: {:foo => "bar"})
#
#That's all. for more information about take a look at _Ramp::AMPClient class.
#
#Note:: Remember that Commands should have the same signature as they have on remote server.
#
#== Credit
#Author::    Dave Thomas  (mailto:lxsameer@gnu.org)
#Copyright:: Copyright (c) 2012 Yellowen Inc
#License::   Distributes under the term of GPLv3

#--
#    RAMP - AMP protocol client implementation in Ruby
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
#++

require 'socket'

require "ramp/version"
require "ramp/command.rb"
require "ramp/fields.rb"

# This module contains all the AMP protocol related classes
module Ramp

  # AmpClient class is responsble for establishing a connection to a AMP server
  class AmpClient

    @@sent_packets = Hash.new

    # host:: address of remote amp server
    # port:: port to connect to.
    # kwarrgs:: is a hash that contains extra optional arguments.
    # * secure:: Use an SSL secured connection
    # * ssl_key:: Path to SSL key.
    # * ssl_cert:: Path to client SSL cert file.
    # * async:: If this argument was true then Ramp use a threaded solution to
    #           send the request and handle the response
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

    # This method will call the given command on the remote server with given
    # arguments in kwargs
    # command:: is a subclass of *Command* class.
    # kwargs:: the arguments for the *command*'s initilize method.
    def call(command, kwargs)

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

    end

    # Private members -----------------------------------
    private
    
    def make_connection 

      begin
        socket = TCPSocket.new @host, @port
      rescue Errno::ECONNREFUSED
        abort("Connection Refused")        
      end

      if @secure
        ctx = OpenSSL::SSL::SSLContext.new()
        ctx.cert = OpenSSL::X509::Certificate.new(File.open(@ssl_cert))
        ctx.key = OpenSSL::PKey::RSA.new(File.open(@ssl_key))
        ctx.ssl_version = :SSLv23
        ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
        ssl_socket.sync_close = true
        ssl_socket.connect
        @socket = ssl_socket
        return 

      end

      @socket = socket

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
        # Generate an exception from _error_code and rise it
        exception = Object.const_set(data[:_error_code], Class.new(StandardError))
        raise exception, data[:_error_description]
      end
            
    end

  end

end
