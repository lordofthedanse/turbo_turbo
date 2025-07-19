# frozen_string_literal: true

require "spec_helper"

RSpec.describe TurboTurbo::FormHelper do
  let(:helper_class) do
    Class.new do
      include TurboTurbo::FormHelper
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::TagHelper
      include ActionView::Context

      # Mock methods for testing
      def content_tag(name, content_or_options_with_block = nil, options = nil, _escape = true, &block)
        if block_given?
          content = capture(&block)
          "<#{name}#{html_attributes(content_or_options_with_block)}>#{content}</#{name}>"
        else
          "<#{name}#{html_attributes(options)}>#{content_or_options_with_block}</#{name}>"
        end
      end

      def concat(string)
        @output ||= ""
        @output += string || ""
      end

      def capture
        old_output = @output
        @output = ""
        yield if block_given?
        result = @output
        @output = old_output
        result
      end

      def form_for(_object, options = {})
        "<form #{html_attributes(options[:html])}>form_for_content</form>"
      end

      def form_with(**options)
        "<form #{html_attributes(options[:html])}>form_with_content</form>"
      end

      def simple_form_for(_object, options = {})
        "<form #{html_attributes(options[:html])}>simple_form_content</form>"
      end

      private

      def html_attributes(attrs)
        return "" unless attrs.is_a?(Hash) && attrs.any?

        " " + attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
      end

      def respond_to?(method_name, include_private = false)
        case method_name
        when :simple_form_for
          @simple_form_available
        else
          super
        end
      end

      public

      def set_simple_form_availability(available)
        @simple_form_available = available
      end
    end
  end

  let(:helper) { helper_class.new }
  let(:mock_object) do
    double("MockModel",
           class: double(model_name: double(to_s: "MockModel")),
           persisted?: false)
  end
  let(:persisted_object) do
    double("PersistedModel",
           class: double(model_name: double(to_s: "PersistedModel")),
           persisted?: true)
  end

  before do
    stub_const("SimpleForm", Class.new)
    helper.set_simple_form_availability(true)
  end

  describe "#turbo_form_for" do
    context "with default options" do
      it "generates form with default turbo modal data attributes" do
        result = helper.turbo_form_for(mock_object, url: "/test")

        expect(result).to include('class="ModalContent-turbo-turbo"')
        expect(result).to include('id="error_message_turbo_turbo"')
        expect(result).to include("simple_form_content")
      end

      it "includes turbo modal target and close action by default" do
        allow(helper).to receive(:simple_form_for) do |_object, options|
          data_attrs = options[:data]
          expect(data_attrs[:turbo_turbo__modal_target]).to eq("form")
          expect(data_attrs[:action]).to eq("turbo:submit-end->turbo-turbo--modal#closeOnSuccess")
          "<form>content</form>"
        end

        helper.turbo_form_for(mock_object, url: "/test")
      end
    end

    context "with custom options" do
      it "merges custom data attributes" do
        allow(helper).to receive(:simple_form_for) do |_object, options|
          data_attrs = options[:data]
          expect(data_attrs[:custom_attr]).to eq("custom_value")
          expect(data_attrs[:turbo_turbo__modal_target]).to eq("form")
          "<form>content</form>"
        end

        helper.turbo_form_for(mock_object, url: "/test", data: { custom_attr: "custom_value" })
      end
    end

    context "with different form builders" do
      it "uses simple_form by default" do
        expect(helper).to receive(:simple_form_for).with(mock_object, anything)
        helper.turbo_form_for(mock_object, url: "/test")
      end

      it "uses form_with when specified" do
        expect(helper).to receive(:form_with).with(hash_including(model: mock_object))
        helper.turbo_form_for(mock_object, url: "/test", builder: :form_with)
      end

      it "uses form_for when specified" do
        expect(helper).to receive(:form_for).with(mock_object, anything)
        helper.turbo_form_for(mock_object, url: "/test", builder: :form_for)
      end

      it "raises error for unknown builder" do
        expect do
          helper.turbo_form_for(mock_object, url: "/test", builder: :unknown)
        end.to raise_error(ArgumentError, /Unknown form builder: unknown/)
      end
    end

    context "when SimpleForm is not available" do
      before do
        helper.set_simple_form_availability(false)
      end

      it "raises error when trying to use simple_form" do
        expect do
          helper.turbo_form_for(mock_object, url: "/test", builder: :simple_form)
        end.to raise_error(/SimpleForm is not available/)
      end
    end

    context "URL handling" do
      it "uses provided URL" do
        allow(helper).to receive(:simple_form_for) do |_object, options|
          expect(options[:url]).to eq("/custom/path")
          "<form>content</form>"
        end

        helper.turbo_form_for(mock_object, url: "/custom/path")
      end

      it "uses object as URL for persisted objects when no URL provided" do
        allow(helper).to receive(:simple_form_for) do |_object, options|
          expect(options[:url]).to eq(persisted_object)
          "<form>content</form>"
        end

        helper.turbo_form_for(persisted_object)
      end
    end
  end

  describe "#turbo_simple_form_for" do
    it "calls turbo_form_for with simple_form builder" do
      expect(helper).to receive(:turbo_form_for).with(mock_object, hash_including(builder: :simple_form))
      helper.turbo_simple_form_for(mock_object, url: "/test")
    end
  end

  describe "#turbo_form_with" do
    it "calls turbo_form_for with form_with builder" do
      expect(helper).to receive(:turbo_form_for).with(mock_object, hash_including(builder: :form_with))
      helper.turbo_form_with(model: mock_object, url: "/test")
    end
  end

  describe "private methods" do
    describe "#build_form_with" do
      it "converts object to model parameter for form_with" do
        expect(helper).to receive(:form_with).with(hash_including(model: mock_object))
        helper.send(:build_form_with, mock_object, { url: "/test" })
      end

      it "removes URL when it matches the object" do
        expect(helper).to receive(:form_with) do |options|
          expect(options[:url]).to be_nil
          expect(options[:model]).to eq(mock_object)
        end
        helper.send(:build_form_with, mock_object, { url: mock_object })
      end
    end

    describe "#build_form_for" do
      it "passes through to form_for" do
        expect(helper).to receive(:form_for).with(mock_object, { url: "/test" })
        helper.send(:build_form_for, mock_object, { url: "/test" })
      end
    end
  end
end
