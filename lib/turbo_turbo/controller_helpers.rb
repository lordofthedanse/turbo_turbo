# frozen_string_literal: true

module TurboTurbo
  module ControllerHelpers
    extend ActiveSupport::Concern
    include StandardActions
    include FormHelper

    included do
      # Configuration for turbo response action groups
      mattr_accessor :turbo_response_actions, default: {
        prepend: %w[create],
        replace: %w[update email_modal],
        remove: %w[destroy archive restore toggle_resolved]
      }

      mattr_accessor :error_response_actions, default: {
        validation_errors: %w[create update upload],
        flash_errors: %w[destroy archive restore]
      }
    end

    # ========================================
    # Main Response Methods
    # ========================================

    def process_turbo_response(object, event, flash_naming_attribute: nil)
      if event
        turbo_success_response(object, flash_naming_attribute)
      else
        turbo_error_response(object, flash_naming_attribute)
      end
    end

    def turbo_success_response(object, flash_naming_attribute)
      render turbo_stream: [
        turbo_behavior_for_success(object),
        replace_turbo_flashes(flash_reference(object, flash_naming_attribute))
      ].compact_blank
    end

    def turbo_error_response(object, flash_naming_attribute = nil)
      if validation_error_action?
        render turbo_stream: turbo_stream.update(
          :error_message_turbo_turbo,
          partial: "turbo_turbo/error_message",
          locals: { message: validation_error_messages(object) }
        ), status: :unprocessable_entity
      elsif flash_error_action?
        render turbo_stream: turbo_stream.replace(
          :flashes_turbo_turbo,
          partial: "turbo_turbo/flashes",
          locals: { flash: turbo_flash_error_message(flash_reference(object, flash_naming_attribute)) }
        )
      end
    end

    def render_turbo_modal(locals = default_locals, partial = default_partial)
      render turbo_stream: turbo_stream.update(:modal_body, partial:, locals:)
    end

    # ========================================
    # Turbo Stream Behavior Methods
    # ========================================

    def turbo_behavior_for_success(object, partial: default_partial)
      if prepend_action?
        turbo_stream.prepend(:search_results, partial:, locals: { "#{default_object_key}": object })
      elsif replace_action?
        turbo_stream.replace(object, partial:, locals: { "#{default_object_key}": object })
      elsif remove_action?
        turbo_stream.remove(object)
      end
    end

    # ========================================
    # Flash Message Methods (I18n-ready)
    # ========================================

    def replace_turbo_flashes(flash_reference)
      turbo_stream.replace(:flashes_turbo_turbo, partial: "turbo_turbo/flashes",
                                                 locals: { flash: turbo_flash_success_message(flash_reference) })
    end

    def turbo_flash_error_message(flash_reference)
      action_verb = action_name == "destroy" ? "delete" : action_name

      { error: I18n.t("turbo_turbo.flash.error.default",
                      action: action_verb,
                      resource: flash_reference,
                      default: "We encountered an error trying to %<action>s %<resource>s.") }
    end

    def turbo_flash_success_message(flash_reference)
      message = I18n.t("turbo_turbo.flash.success.#{action_name}",
                       resource: flash_reference,
                       action: action_name,
                       default: I18n.t("turbo_turbo.flash.success.default",
                                       resource: flash_reference,
                                       action: action_name,
                                       default: "#{flash_reference} #{action_name}d!"))

      { success: message }
    end

    def validation_error_messages(object)
      bulleted_errors = object.errors.full_messages.map { |e| "<li class='text-red-700'>#{e}</li>" }.join
      "<ul>#{bulleted_errors}</ul>"
    end

    # ========================================
    # Action Group Helper Methods
    # ========================================

    def prepend_action?
      turbo_response_actions[:prepend].include?(action_name)
    end

    def replace_action?
      turbo_response_actions[:replace].include?(action_name)
    end

    def remove_action?
      turbo_response_actions[:remove].include?(action_name)
    end

    def validation_error_action?
      error_response_actions[:validation_errors].include?(action_name)
    end

    def flash_error_action?
      error_response_actions[:flash_errors].include?(action_name)
    end

    # ========================================
    # Utility/Helper Methods
    # ========================================

    def flash_reference(object, flash_naming_attribute)
      flash_naming_attribute ? object.send(flash_naming_attribute).titleize : object.class.name.titleize
    end

    def default_partial
      action = %w[create update].include?(action_name) ? controller_name.singularize : action_name
      "#{controller_path}/#{action}"
    end

    def default_locals
      key = default_object_key
      { "#{key}": send(key) }
    end

    def default_object_key
      controller_name.singularize.to_sym
    end
  end
end
