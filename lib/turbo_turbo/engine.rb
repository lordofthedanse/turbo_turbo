# frozen_string_literal: true

require 'rails/engine'

module TurboTurbo
  class Engine < ::Rails::Engine
    isolate_namespace TurboTurbo

    initializer 'turbo_turbo.setup' do |_app|
      ActiveSupport.on_load(:action_controller_base) do
        include TurboTurbo::ControllerHelpers
      end

      ActiveSupport.on_load(:action_view) do
        include TurboTurbo::FormHelper
      end
    end
  end
end
