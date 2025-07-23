# frozen_string_literal: true

require "turbo_turbo/version"
require "turbo_turbo/engine"
require "turbo_turbo/parameter_sanitizer"
require "turbo_turbo/standard_actions"
require "turbo_turbo/form_helper"
require "turbo_turbo/controller_helpers"

# Load test helpers if we're in a test environment
require "turbo_turbo/test_helpers" if defined?(RSpec) || (defined?(Rails) && Rails.env.test?)

module TurboTurbo
  class Error < StandardError; end
end
