# frozen_string_literal: true

module TurboTurbo
  class ModalComponent < ViewComponent::Base
    def initialize(show_close: false)
      @show_close = show_close
    end
  end
end
