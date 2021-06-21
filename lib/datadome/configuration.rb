# frozen_string_literal: true

require "logger"

module Datadome
  class Configuration

    def initialize
      @api_server = "api.datadome.co"
      @exclude_matchers = []
      @include_matchers = []
      @monitoring_mode = false
    end

    attr_accessor :api_key, :api_server, :exclude_matchers, :include_matchers, :monitoring_mode

  end
end
