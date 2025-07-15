# frozen_string_literal: true

module TurboTurbo
  # FormHelper provides a standardized way to create turbo-enabled modal forms
  # that integrate seamlessly with the TurboTurbo modal system.
  #
  # == Basic Usage
  #
  # Instead of writing:
  #   = simple_form_for service_provider, url: [:admin, service_provider],
  #       data: {
  #         turbo_turbo__modal_target: "form",
  #         action: "turbo:submit-end->turbo-turbo--modal#closeOnSuccess"
  #       } do |form|
  #     .ModalContent-turbo-turbo
  #       #error_message_turbo_turbo
  #       [user-specific fields here]
  #
  # You can now write:
  #   <%= turbo_form_for(service_provider, url: [:admin, service_provider]) do |form| %>
  #     <!-- just the form fields -->
  #   <% end %>
  #
  # == Form Builder Support
  #
  # The helper supports multiple form builders:
  #   - SimpleForm (default): turbo_form_for(object, builder: :simple_form)
  #   - Rails form_with: turbo_form_for(object, builder: :form_with)
  #   - Rails form_for: turbo_form_for(object, builder: :form_for)
  #
  # == Customization Options
  #
  #   turbo_form_for(object,
  #     url: custom_path,
  #     builder: :form_with,              # Form builder to use
  #     data: { custom_attr: "value" }    # Additional data attributes
  #   )
  #
  module FormHelper
    extend ActiveSupport::Concern

    # Main method for creating turbo-enabled modal forms
    #
    # @param object [ActiveRecord::Base] The object for the form
    # @param options [Hash] Form options including url, method, etc.
    # @option options [Symbol] :builder (:simple_form) Form builder to use (:simple_form, :form_with, :form_for)
    # @option options [String] :url The form submission URL
    # @option options [Symbol] :method HTTP method for the form
    # @option options [Hash] :data Additional data attributes to merge
    # @option options [Hash] :html Additional HTML attributes for the form
    # @yield [form] Form builder object
    def turbo_form_for(object, options = {}, &)
      # Extract and set defaults
      builder_type = options.delete(:builder) || :simple_form

      # Build default data attributes for turbo modal integration
      default_data = {
        turbo_turbo__modal_target: 'form'
      }

      # Add auto-close action if enabled
      default_data[:action] = 'turbo:submit-end->turbo-turbo--modal#closeOnSuccess'

      # Merge user-provided data attributes
      user_data = options.delete(:data) || {}
      merged_data = default_data.merge(user_data)

      # Set up form options
      form_options = options.merge(data: merged_data)

      # Ensure URL is set if not provided
      unless form_options[:url]
        if object.respond_to?(:persisted?) && object.persisted?
          form_options[:url] = object
        else
          # Try to infer URL from object class
          object.class.model_name
          form_options[:url] = [:admin, object] if defined?(controller) && controller.class.name.include?('Admin')
        end
      end

      # Generate the form based on builder type
      form_html = case builder_type
                  when :simple_form
                    build_simple_form(object, form_options, &)
                  when :form_with
                    build_form_with(object, form_options, &)
                  when :form_for
                    build_form_for(object, form_options, &)
                  else
                    raise ArgumentError,
                          "Unknown form builder: #{builder_type}. Supported builders: :simple_form, :form_with, :form_for"
                  end

      # Wrap the form in modal content structure
      content_tag(:div, class: 'ModalContent-turbo-turbo') do
        concat content_tag(:div, '', id: 'error_message_turbo_turbo')
        concat form_html
      end
    end

    # Convenience method for SimpleForm (most common case)
    def turbo_simple_form_for(object, options = {}, &)
      turbo_form_for(object, options.merge(builder: :simple_form), &)
    end

    # Convenience method for Rails form_with
    def turbo_form_with(model:, **options, &)
      turbo_form_for(model, options.merge(builder: :form_with), &)
    end

    private

    def build_simple_form(object, options, &)
      unless defined?(SimpleForm) && respond_to?(:simple_form_for)
        raise 'SimpleForm is not available. Install the simple_form gem or use a different builder.'
      end

      simple_form_for(object, options, &)
    end

    def build_form_with(object, options, &)
      # Convert object-based options to form_with format
      form_with_options = options.dup
      form_with_options[:model] = object
      form_with_options.delete(:url) if form_with_options[:url] == object

      form_with(**form_with_options, &)
    end

    def build_form_for(object, options, &)
      form_for(object, options, &)
    end
  end
end
