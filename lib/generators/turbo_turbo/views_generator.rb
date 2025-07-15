# frozen_string_literal: true

require 'rails/generators/base'

module TurboTurbo
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      desc 'Copy TurboTurbo views for customization'
      source_root File.expand_path('../../..', __dir__)

      def copy_view_components
        empty_directory 'app/components/turbo_turbo'
        empty_directory 'app/components/turbo_turbo/alerts'
        copy_file 'app/components/turbo_turbo/alerts/alert_component.rb',
                  'app/components/turbo_turbo/alerts/alert_component.rb'
        copy_file 'app/components/turbo_turbo/alerts/success_component.rb',
                  'app/components/turbo_turbo/alerts/success_component.rb'
        copy_file 'app/components/turbo_turbo/alerts/error_component.rb',
                  'app/components/turbo_turbo/alerts/error_component.rb'
        copy_file 'app/components/turbo_turbo/alerts/info_component.rb',
                  'app/components/turbo_turbo/alerts/info_component.rb'
        copy_file 'app/components/turbo_turbo/alerts/warning_component.rb',
                  'app/components/turbo_turbo/alerts/warning_component.rb'
        copy_file 'app/components/turbo_turbo/modal_component.rb', 'app/components/turbo_turbo/modal_component.rb'
        copy_file 'app/components/turbo_turbo/modal_footer_component.rb',
                  'app/components/turbo_turbo/modal_footer_component.rb'
      end

      def copy_view_templates
        copy_file 'app/components/turbo_turbo/alerts/alert_component.html.erb',
                  'app/components/turbo_turbo/alerts/alert_component.html.erb'
        copy_file 'app/components/turbo_turbo/alerts/success_component.html.erb',
                  'app/components/turbo_turbo/alerts/success_component.html.erb'
        copy_file 'app/components/turbo_turbo/alerts/error_component.html.erb',
                  'app/components/turbo_turbo/alerts/error_component.html.erb'
        copy_file 'app/components/turbo_turbo/alerts/info_component.html.erb',
                  'app/components/turbo_turbo/alerts/info_component.html.erb'
        copy_file 'app/components/turbo_turbo/alerts/warning_component.html.erb',
                  'app/components/turbo_turbo/alerts/warning_component.html.erb'
        copy_file 'app/components/turbo_turbo/modal_component.html.erb',
                  'app/components/turbo_turbo/modal_component.html.erb'
        copy_file 'app/components/turbo_turbo/modal_footer_component.html.erb',
                  'app/components/turbo_turbo/modal_footer_component.html.erb'
      end

      def display_instructions
        say "\n\nTurboTurbo views have been copied for customization!", :green
        say "\nThe following files have been copied to your application:"
        say '• Alert ViewComponents (turbo_turbo/alerts/)'
        say '• Modal ViewComponents (turbo_turbo/)'
        say '• All component templates (.html.erb)'
        say "\nYou can now customize these components as needed."
        say 'Note: Components in your app/ directory will override the gem versions.'
      end
    end
  end
end
