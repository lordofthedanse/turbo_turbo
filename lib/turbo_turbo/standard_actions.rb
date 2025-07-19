# frozen_string_literal: true

module TurboTurbo
  module StandardActions
    extend ActiveSupport::Concern

    class_methods do
      # DSL method to automatically generate standard CRUD actions
      #
      # Usage:
      #   class MessagesController < ApplicationController
      #     turbo_actions :create, :update, :destroy
      #
      #     private
      #
      #     def message_params
      #       params.require(:message).permit(:content, :title)
      #     end
      #   end
      def turbo_actions(*actions)
        actions.each do |action|
          unless %i[
            create update destroy show new edit
          ].include?(action)
            raise ArgumentError,
                  "Unknown action: #{action}. Supported actions: :create, :update, :destroy, :show, :new, :edit"
          end

          send(:"define_turbo_#{action}_action")
        end
      end

      private

      def define_turbo_create_action
        define_method :create do
          model_instance = model_class.new(create_params)
          process_turbo_response(model_instance, model_instance.save)
        end
      end

      def define_turbo_update_action
        define_method :update do
          process_turbo_response(model_instance, model_instance.update(send(model_params_method)))
        end
      end

      def define_turbo_destroy_action
        define_method :destroy do
          process_turbo_response(model_instance, model_instance.destroy)
        end
      end

      %i[show new edit].each do |action|
        define_method :"define_turbo_#{action}_action" do
          define_method action do
            render_turbo_modal({ model_name: send("model_instance_for_#{action}") })
          end
        end
      end
    end

    # Instance methods - can be overridden in controllers
    def create_params
      send(model_params_method)
    end

    def model_params_method
      "#{model_name}_params"
    end

    def model_instance_for_show
      model_instance
    end

    def model_instance_for_edit
      model_instance
    end

    def model_instance_for_new
      model_class.new
    end

    def model_instance
      model_class.find(params[:id])
    end

    def model_class
      self.class.controller_name.classify.constantize
    end

    def model_name
      self.class.controller_name.singularize
    end
  end
end
