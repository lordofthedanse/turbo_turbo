# frozen_string_literal: true

module TurboTurbo
  module Alerts
    class WarningComponent < ViewComponent::Base
      def initialize(flash_contents)
        @header = flash_contents[:header]
        @message = flash_contents[:message]
      end
    end
  end
end
