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
  module Fields

    class StringField < String

      def self.to_o data
        String.new data
      end

    end

    class IntegerField < Integer
    
      def self.to_o data
        Integer.new data
      end

    end

    class JsonField < Hash
      
      require 'json'

      def to_s
        JSON.dump(self)
      end

      def self.to_o data
        JSON.load(data)
      end

    end

  end
end
