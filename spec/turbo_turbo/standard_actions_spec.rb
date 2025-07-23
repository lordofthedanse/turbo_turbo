# frozen_string_literal: true

require "spec_helper"

RSpec.describe TurboTurbo::StandardActions do
  # Mock controller for testing
  let(:controller_class) do
    Class.new do
      include TurboTurbo::StandardActions

      def self.controller_name
        "messages"
      end

      def params
        @params ||= {}
      end

      attr_writer :params

      # Mock the methods that would be available in a real controller
      def process_turbo_response(object, result)
        "process_turbo_response called with #{object.class.name} and #{result}"
      end

      def render_turbo_modal
        "render_turbo_modal called"
      end

      private

      def message_params
        { content: "Test content", title: "Test title" }
      end
    end
  end

  # Mock Message model
  let(:message_class) do
    Class.new do
      def self.name
        "Message"
      end

      def self.new(params = {})
        instance = allocate
        instance.instance_variable_set(:@attributes, params)
        instance
      end

      def self.find(id)
        instance = allocate
        instance.instance_variable_set(:@attributes, { id: id })
        instance
      end

      def save
        true
      end

      def update(params)
        @attributes.merge!(params)
        true
      end

      def destroy
        true
      end

      def class
        message_class
      end
    end
  end

  let(:controller_instance) { controller_class.new }

  before do
    # Mock the constantize method to return our mock Message class
    allow(controller_class).to receive(:controller_name).and_return("messages")
    allow("messages".classify).to receive(:constantize).and_return(message_class)
    stub_const("Message", message_class)
  end

  describe ".turbo_actions" do
    it "defines create action when :create is specified" do
      controller_class.turbo_actions :create

      expect(controller_instance).to respond_to(:create)
    end

    it "defines update action when :update is specified" do
      controller_class.turbo_actions :update

      expect(controller_instance).to respond_to(:update)
    end

    it "defines destroy action when :destroy is specified" do
      controller_class.turbo_actions :destroy

      expect(controller_instance).to respond_to(:destroy)
    end

    it "defines show action when :show is specified" do
      controller_class.turbo_actions :show

      expect(controller_instance).to respond_to(:show)
    end

    it "defines new action when :new is specified" do
      controller_class.turbo_actions :new

      expect(controller_instance).to respond_to(:new)
    end

    it "defines edit action when :edit is specified" do
      controller_class.turbo_actions :edit

      expect(controller_instance).to respond_to(:edit)
    end

    it "defines multiple actions when multiple symbols are provided" do
      controller_class.turbo_actions :create, :update, :destroy

      expect(controller_instance).to respond_to(:create)
      expect(controller_instance).to respond_to(:update)
      expect(controller_instance).to respond_to(:destroy)
    end

    it "raises ArgumentError for unsupported actions" do
      expect do
        controller_class.turbo_actions :unsupported_action
      end.to raise_error(ArgumentError,
                         "Unknown action: unsupported_action. Supported actions: :create, :update, :destroy, :show, :new, :edit")
    end
  end

  describe "generated actions" do
    before do
      controller_class.turbo_actions :create, :update, :destroy, :show, :new, :edit
    end

    describe "#create" do
      it "creates new model instance and calls process_turbo_response" do
        expect(controller_instance).to receive(:process_turbo_response).with(
          an_instance_of(message_class), true
        )

        controller_instance.create
      end
    end

    describe "#update" do
      it "finds model instance and calls process_turbo_response" do
        controller_instance.params = { id: 1 }

        expect(controller_instance).to receive(:process_turbo_response).with(
          an_instance_of(message_class), true
        )

        controller_instance.update
      end
    end

    describe "#destroy" do
      it "finds model instance and calls process_turbo_response" do
        controller_instance.params = { id: 1 }

        expect(controller_instance).to receive(:process_turbo_response).with(
          an_instance_of(message_class), true
        )

        controller_instance.destroy
      end
    end

    describe "#show" do
      it "finds model instance and calls render_turbo_modal" do
        controller_instance.params = { id: 1 }

        expect(controller_instance).to receive(:render_turbo_modal)

        controller_instance.show
      end
    end

    describe "#new" do
      it "creates new model instance and calls render_turbo_modal" do
        expect(controller_instance).to receive(:render_turbo_modal)

        controller_instance.new
      end
    end

    describe "#edit" do
      it "finds model instance and calls render_turbo_modal" do
        controller_instance.params = { id: 1 }

        expect(controller_instance).to receive(:render_turbo_modal)

        controller_instance.edit
      end
    end
  end

  describe "instance helper methods" do
    describe "#model_class" do
      it "returns the constantized controller name" do
        expect(controller_instance.send(:model_class)).to eq(message_class)
      end
    end

    describe "#model_name" do
      it "returns the singularized controller name" do
        expect(controller_instance.send(:model_name)).to eq("message")
      end
    end

    describe "#model_params_method" do
      it "returns the params method name for the model" do
        expect(controller_instance.model_params_method).to eq("message_params")
      end
    end

    describe "#create_params" do
      it "calls the model params method" do
        expect(controller_instance).to receive(:message_params).and_return({ content: "test" })
        expect(controller_instance.create_params).to eq({ content: "test" })
      end
    end

    describe "#model_instance_for_new" do
      it "returns a new model instance" do
        expect(controller_instance.model_instance_for_new).to be_an_instance_of(message_class)
      end
    end

    describe "#model_instance_for_show" do
      it "returns found model instance" do
        controller_instance.params = { id: 1 }
        expect(controller_instance.model_instance_for_show).to be_an_instance_of(message_class)
      end
    end

    describe "#model_instance_for_edit" do
      it "returns found model instance" do
        controller_instance.params = { id: 1 }
        expect(controller_instance.model_instance_for_edit).to be_an_instance_of(message_class)
      end
    end
  end
end
