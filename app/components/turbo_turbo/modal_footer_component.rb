# frozen_string_literal: true

module TurboTurbo
  class ModalFooterComponent < ViewComponent::Base
    def initialize(skip_close: false, close_label: 'Cancel')
      @skip_close = skip_close
      @close_label = close_label
    end
  end
end
