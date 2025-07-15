# frozen_string_literal: true

module TurboTurbo
  module ParameterSanitizer
    extend ActiveSupport::Concern

    # Sanitizes parameters based on the model schema
    # Converts boolean fields and trims string inputs
    #
    # Usage:
    #   params.require(:user).permit(:name, :active).sanitize_for_model(:user)
    #
    # @param model_key [Symbol] The key to deduce the model from (e.g., :user for User model)
    # @return [ActionController::Parameters] The sanitized parameters
    def sanitize_for_model(model_key)
      model = model_from_key(model_key)
      convert_boolean_params(model)
      trim_input_strings
      self
    end

    private

    # Converts string boolean values to actual booleans based on model schema
    def convert_boolean_params(model)
      boolean_columns = columns_for(model, [:boolean])
      each { |k, v| self[k] = convert_to_boolean(v) if boolean_columns.include?(k.to_s) }
    end

    # Trims whitespace from strings and cleans arrays
    def trim_input_strings
      each do |k, v|
        if v.is_a?(Array)
          self[k] = v.map { |item| item.is_a?(String) ? item.strip : item }.select(&:present?)
        elsif v.is_a?(String)
          self[k] = v.strip
        end
      end
    end

    # Gets columns of specified types from the model
    def columns_for(model, types)
      model.columns_hash.select { |_, column| types.include?(column.type) }.keys
    end

    # Deduces the model class from a symbol key
    def model_from_key(key)
      model_name = key.to_s.classify.safe_constantize
      raise ArgumentError, "Model could not be deduced from symbol (#{key})" unless model_name

      model_name
    end

    # Converts string boolean values to actual booleans
    def convert_to_boolean(field)
      case field
      when 'false', '0'
        false
      when 'true', '1'
        true
      else
        field
      end
    end
  end
end

# Extend ActionController::Parameters with the sanitization methods
ActionController::Parameters.include(TurboTurbo::ParameterSanitizer)
