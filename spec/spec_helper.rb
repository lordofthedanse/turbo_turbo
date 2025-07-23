# frozen_string_literal: true

require "bundler/setup"

ENV["RAILS_ENV"] = "test"

require "rails"
require "rails/all"
require "action_controller"
require "turbo-rails"
require "view_component"
require "view_component/test_helpers"
require "rspec"

module TestApp
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.cache_classes = true
    config.eager_load = false
    config.consider_all_requests_local = true
    config.active_support.deprecation = :log
    config.log_level = :fatal
    config.secret_key_base = "test"

    config.hosts.clear
  end
end

Rails.application.initialize!

require "turbo_turbo"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include ViewComponent::TestHelpers, type: :component
end
