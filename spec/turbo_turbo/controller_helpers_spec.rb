# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TurboTurbo::ControllerHelpers do
  let(:controller_class) do
    Class.new do
      include TurboTurbo::ControllerHelpers

      attr_accessor :action_name, :controller_name, :controller_path

      def initialize
        @action_name = 'create'
        @controller_name = 'messages'
        @controller_path = 'messages'
      end

      def turbo_stream
        @turbo_stream ||= MockTurboStream.new
      end

      def render(options = {})
        options
      end
    end
  end

  let(:controller) { controller_class.new }
  let(:mock_object) do
    double('Message',
           errors: double(full_messages: ["Name can't be blank", 'Email is invalid']),
           class: double(name: 'Message'))
  end

  class MockTurboStream
    def update(target, options = {})
      { action: :update, target: target, options: options }
    end

    def replace(target, options = {})
      { action: :replace, target: target, options: options }
    end

    def prepend(target, options = {})
      { action: :prepend, target: target, options: options }
    end

    def remove(target)
      { action: :remove, target: target }
    end
  end

  describe '#validation_error_messages' do
    it 'formats error messages as HTML list' do
      result = controller.validation_error_messages(mock_object)
      expect(result).to eq("<ul><li class='text-red-700'>Name can't be blank</li><li class='text-red-700'>Email is invalid</li></ul>")
    end
  end

  describe '#default_object_key' do
    it 'returns singularized controller name as symbol' do
      expect(controller.default_object_key).to eq(:message)
    end
  end

  describe '#default_partial' do
    context 'for create action' do
      it 'returns singularized controller path' do
        controller.action_name = 'create'
        expect(controller.default_partial).to eq('messages/message')
      end
    end

    context 'for custom action' do
      it 'returns action name' do
        controller.action_name = 'email_modal'
        expect(controller.default_partial).to eq('messages/email_modal')
      end
    end
  end

  describe '#turbo_flash_success_message' do
    it 'returns appropriate success message for destroy' do
      controller.action_name = 'destroy'
      result = controller.turbo_flash_success_message('Message')
      expect(result).to eq({ success: 'Message deleted!' })
    end

    it 'returns appropriate success message for other actions' do
      controller.action_name = 'create'
      result = controller.turbo_flash_success_message('Message')
      expect(result).to eq({ success: 'Message created!' })
    end
  end

  describe '#turbo_flash_error_message' do
    it 'returns appropriate error message' do
      controller.action_name = 'create'
      result = controller.turbo_flash_error_message('Message')
      expect(result).to eq({ error: 'We encountered an error trying to create Message.' })
    end

    it 'handles destroy action specially' do
      controller.action_name = 'destroy'
      result = controller.turbo_flash_error_message('Message')
      expect(result).to eq({ error: 'We encountered an error trying to delete Message.' })
    end
  end
end
