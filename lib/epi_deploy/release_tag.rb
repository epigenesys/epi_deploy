# frozen_string_literal: true

require "time"

module EpiDeploy
  class ReleaseTag

    attr_reader :timestamp
    attr_accessor :commit
    attr_accessor :version

    REGEXP = /\A(?<timestamp>\d{4}[a-z]{3}\d{2}-\d{4})-(?<commit>[0-9a-f]+)-v(?<version>\d+)\z/
    TIMESTAMP_FORMAT = "%Y%b%d-%H%M"

    def initialize(timestamp: nil, commit:, version:)
      timestamp ||= time_class.now

      self.timestamp = timestamp
      self.commit = commit
      self.version = version.to_i
    end

    def self.parse(string)
      match = REGEXP.match(string)
      return nil if match.nil?

      kwargs = match.named_captures.to_h { |k, v| [k.to_sym, v] }
      new(**kwargs)
    end

    def timestamp=(timestamp)
      @timestamp = parse_timestamp(timestamp)
    end

    def increment(timestamp: nil, commit:)
      self.class.new timestamp:, commit:, version: version + 1
    end

    def to_s
      "#{dump_timestamp(timestamp)}-#{commit}-v#{version}"
    end

    private

    def dump_timestamp(timestamp)
      timestamp.strftime(TIMESTAMP_FORMAT).downcase
    end

    def parse_timestamp(timestamp)
      if timestamp.is_a? String
        time_class.strptime timestamp, TIMESTAMP_FORMAT
      else
        timestamp
      end
    end

    # Use Time.zone if we have it (i.e. Rails), otherwise use Time
    def time_class
      if Time.respond_to? :zone
        Time.zone
      else
        Time
      end
    end

  end
end
