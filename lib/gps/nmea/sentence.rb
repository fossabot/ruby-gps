module Gps
  module Nmea
    class Sentence
      attr_accessor :line

      def self.parse(line)
        case
        when line.start_with?('$GPGGA')
          Gga.new line
        when line.start_with?('$GPGLL')
          Gll.new line
        when line.start_with?('$GPGSV')
          Gsv.new line
        when line.start_with?('$GPGSA')
          Gsa.new line
        when line.start_with?('$GPVTG')
          Vtg.new line
        else
          nil
        end
      end

      def checksum_valid?
        get_checksum == generate_checksum
      end

      def get_checksum
        line.split(',')[-1].split('*')[1].to_i 16
      end

      def generate_checksum
        data = line.gsub('$', '').split('*')[0]
        res = 0
        data.split('').each do |c|
          res ^= c.ord
        end
        res
      end

      def lat_dec
        return nil if @latitude.nil?
        return nil if @latitude_direction.nil?

        lat, lat_dec = @latitude.to_s.split '.'
        lat = lat.rjust 4, '0'
        res = lat[0..1].to_i + ("#{lat[2..3]}.#{lat_dec}".to_f / 60.0)
        res *= -1 if @latitude_direction == 'S'
        res
      end

      def long_dec
        return nil if @longitude.nil?
        return nil if @longitude_direction.nil?

        long, long_dec = @longitude.to_s.split '.'
        long = long.rjust 5, '0'
        res = long[0..2].to_i + ("#{long[3..4]}.#{long_dec}".to_f / 60.0)
        res *= -1 if @longitude_direction == 'W'
        res
      end

      def lat_long_dec
        return nil if @latitude.nil? || @longitude.nil? ||
                      @latitude_direction.nil? || @longitude_direction.nil?
        "#{lat_dec} #{long_dec}"
      end

      def to_h
        self.class.instance_methods(false)
          .reject { |a| a.to_s.end_with? '=' }
          .map { |a| [a.to_s, self.send(a)] }
          .to_h.merge({ type: self.class.to_s.split('::').last.upcase })
      end

      def to_json(pretty=false)
        require 'json'
        if pretty
          JSON.pretty_generate to_h
        else
          to_h.to_json
        end
      end

      protected

      def fill_parts
        @parts = @line.split(',')[1..]
        @parts[-1].gsub! /\*.+$/, ''
      end
    end
  end
end
