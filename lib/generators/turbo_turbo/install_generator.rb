# frozen_string_literal: true

require "rails/generators/base"
require "fileutils"

module TurboTurbo
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install TurboTurbo files"
      source_root File.expand_path("templates", __dir__)

      def install_javascript_controllers
        empty_directory "app/javascript/controllers/turbo_turbo"
        copy_file "turbo_turbo/modal_controller.js", "app/javascript/controllers/turbo_turbo/modal_controller.js"
        copy_file "turbo_turbo/flash_controller.js", "app/javascript/controllers/turbo_turbo/flash_controller.js"
      end

      def register_stimulus_controllers
        index_file = "app/javascript/controllers/index.js"

        unless File.exist?(index_file)
          say "Warning: Could not find #{index_file}", :yellow
          return
        end

        content = File.read(index_file)

        # Check if TurboTurbo controllers are already registered
        if content.include?("turbo-turbo--modal") && content.include?("turbo-turbo--flash")
          say "TurboTurbo controllers already registered in #{index_file}", :blue
          return
        end

        # Add import statements and registrations
        turbo_turbo_imports = <<~JS

          // TurboTurbo controllers
          import TurboTurboModalController from "./turbo_turbo/modal_controller"
          import TurboTurboFlashController from "./turbo_turbo/flash_controller"

          application.register("turbo-turbo--modal", TurboTurboModalController)
          application.register("turbo-turbo--flash", TurboTurboFlashController)
        JS

        # Insert before the last line (usually eagerLoadControllersFrom)
        lines = content.split("\n")
        insert_index = lines.rindex { |line| line.strip.length.positive? && !line.strip.start_with?("//") }

        if insert_index
          lines.insert(insert_index + 1, turbo_turbo_imports)
          File.write(index_file, lines.join("\n"))
          say "Added TurboTurbo controller registrations to #{index_file}", :green
        else
          say "Warning: Could not determine where to insert TurboTurbo registrations in #{index_file}", :yellow
        end
      end

      def install_layout_files
        empty_directory "app/views/turbo_turbo"
        copy_file "turbo_turbo/_flashes.html.erb", "app/views/turbo_turbo/_flashes.html.erb"
        copy_file "turbo_turbo/_modal_background.html.erb", "app/views/turbo_turbo/_modal_background.html.erb"
        copy_file "turbo_turbo/_error_message.html.erb", "app/views/turbo_turbo/_error_message.html.erb"
      end

      def modify_application_controller
        controller_file = "app/controllers/application_controller.rb"

        unless File.exist?(controller_file)
          say "Warning: Could not find #{controller_file}", :yellow
          return
        end

        content = File.read(controller_file)
        original_content = content.dup

        # Add include TurboTurbo::ControllerHelpers if not present
        unless content.include?("include TurboTurbo::ControllerHelpers")
          content = content.gsub(/(class ApplicationController < ActionController::Base\s*\n)/) do
            "#{::Regexp.last_match(1)}  include TurboTurbo::ControllerHelpers\n\n"
          end
        end

        # Add flash types if not present
        unless content.include?("add_flash_types") || content.match?(/add_flash_types\s*:success.*:error.*:warning.*:info/)
          content = content.gsub(/(include TurboTurbo::ControllerHelpers\s*\n)/) do
            "#{::Regexp.last_match(1)}  add_flash_types :success, :error, :warning, :info\n"
          end
        end

        if content == original_content
          say "#{controller_file} already includes TurboTurbo configuration", :blue
        else
          File.write(controller_file, content)
          say "Modified #{controller_file} to include TurboTurbo helpers and flash types", :green
        end
      end

      def add_css_import
        copy_css_file_to_app
        add_css_import_to_main_file
      end

      private

      def copy_css_file_to_app
        # Copy the TurboTurbo CSS files from the gem to the app
        gem_css_dir = File.join(gem_root, "app/assets/stylesheets")
        app_css_dir = "app/assets/stylesheets"

        # CSS subdirectory (now contains base.css and component CSS files)
        gem_css_subdir = File.join(gem_css_dir, "turbo_turbo")
        app_css_subdir = File.join(app_css_dir, "turbo_turbo")

        unless File.exist?(gem_css_subdir)
          say "Warning: Could not find turbo_turbo CSS directory in the gem", :red
          return
        end

        if File.exist?(app_css_subdir)
          say "TurboTurbo CSS directory already exists in #{app_css_dir}", :blue
          return
        end

        # Copy CSS subdirectory (contains base.css and component files)
        FileUtils.cp_r(gem_css_subdir, app_css_subdir)

        say "Copied TurboTurbo CSS files to #{app_css_dir}/turbo_turbo", :green
      end

      def add_css_import_to_main_file
        css_files = [
          "app/assets/stylesheets/application.tailwind.css",
          "app/assets/stylesheets/application.css"
        ]

        css_file = css_files.find { |file| File.exist?(file) }

        unless css_file
          say "Warning: Could not find application.tailwind.css or application.css", :red
          say "Please manually add '@import \"./turbo_turbo.css\";' to your main CSS file", :red
          return
        end

        content = File.read(css_file)

        # Check if import already exists (check for both old and new import formats)
        if content.include?('@import "turbo_turbo"') || content.include?('@import "./turbo_turbo"') || content.include?('@import "./turbo_turbo.css"') || content.include?('@import "./turbo_turbo/base"')
          say "TurboTurbo CSS import already exists in #{css_file}", :blue
          return
        end

        # Add import at the top of the file (using relative path to base.css)
        content = "@import \"./turbo_turbo/base\";\n\n#{content}"
        File.write(css_file, content)
        say "Added TurboTurbo CSS import to #{css_file}", :green
      end

      def gem_root
        @gem_root ||= File.expand_path("../../..", __dir__)
      end

      def modify_layout_file
        layout_files = [
          "app/views/layouts/application.html.erb",
          "app/views/layouts/application.html.slim"
        ]

        layout_file = layout_files.find { |file| File.exist?(file) }

        unless layout_file
          say "Warning: Could not find application layout file", :yellow
          return
        end

        content = File.read(layout_file)
        original_content = content.dup

        content = if layout_file.end_with?(".slim")
                    modify_slim_layout(content)
                  else
                    modify_erb_layout(content)
                  end

        if content == original_content
          say "#{layout_file} already includes TurboTurbo components", :blue
        else
          File.write(layout_file, content)
          say "Modified #{layout_file} to include TurboTurbo components", :green
        end
      end

      def install_routes
        # Copy routes file to config/routes/
        empty_directory "config/routes"
        copy_file "config/routes/turbo_turbo.rb", "config/routes/turbo_turbo.rb"

        # Add draw(:turbo_turbo) to main routes.rb
        routes_file = "config/routes.rb"

        unless File.exist?(routes_file)
          say "Warning: Could not find #{routes_file}", :yellow
          return
        end

        content = File.read(routes_file)

        # Check if draw(:turbo_turbo) already exists
        if content.include?("draw(:turbo_turbo)") || content.include?('draw("turbo_turbo")')
          say "TurboTurbo routes already included in #{routes_file}", :blue
          return
        end

        # Add draw(:turbo_turbo) before the final 'end'
        content = content.gsub(/(\s*end\s*)$/) do
          "  draw(:turbo_turbo)\n#{::Regexp.last_match(1)}"
        end

        File.write(routes_file, content)
        say "Added draw(:turbo_turbo) to #{routes_file}", :green
      end

      def display_instructions
        say "\n\nTurboTurbo has been installed!", :green
        say "\nWhat was installed:"
        say "✅ JavaScript controllers copied to app/javascript/controllers/turbo_turbo/"
        say "✅ Stimulus controllers registered in index.js"
        say "✅ ApplicationController configured with TurboTurbo::ControllerHelpers"
        say "✅ Flash types configured (:success, :error, :warning, :info)"
        say "✅ CSS files copied to app/assets/stylesheets/turbo_turbo/"
        say "✅ CSS import added to main stylesheet"
        say "✅ Body tag configured with turbo-turbo--modal controller"
        say "✅ Flash messages render added"
        say "✅ Modal background render added"
        say "✅ TurboTurbo::ModalComponent render added"
        say "✅ TurboTurbo routes template copied to config/routes/turbo_turbo.rb"
        say "✅ draw(:turbo_turbo) added to config/routes.rb"
        say "\nNext steps:"
        say "🚀 You're ready to use TurboTurbo! Start by adding turbo_actions to your controllers."
        say "📝 Add your modal routes to config/routes/turbo_turbo.rb"
        say "\nOptional:"
        say "• Run 'rails generate turbo_turbo:views' to copy ViewComponents for customization"
        say "• Run 'rails generate turbo_turbo:layout [LAYOUT_NAME]' for custom layouts"
        say "\nFor usage examples, see: https://github.com/lordofthedanse/turbo_turbo"
      end

      def modify_erb_layout(content)
        # Add turbo-turbo--modal to data-controller if not present
        if content.match?(/data-controller\s*=\s*["'][^"']*["']/)
          # data-controller exists, check if turbo-turbo--modal is present
          unless content.match?(/data-controller\s*=\s*["'][^"']*\bturbo-turbo--modal\b[^"']*["']/)
            content = content.gsub(/(data-controller\s*=\s*["'])([^"']*)(['"])/) do
              prefix = ::Regexp.last_match(1)
              controller_list = ::Regexp.last_match(2)
              suffix = ::Regexp.last_match(3)
              controllers = controller_list.strip.split(/\s+/)
              controllers << "turbo-turbo--modal" unless controllers.include?("turbo-turbo--modal")
              "#{prefix}#{controllers.join(' ')}#{suffix}"
            end
          end
        else
          # Add data-controller with turbo-turbo--modal to body tag
          content = content.gsub(/(<body[^>]*?)>/) do
            body_tag = ::Regexp.last_match(1)
            "#{body_tag} data-controller=\"turbo-turbo--modal\">"
          end
        end

        # Add layout renders after body tag if not present
        unless content.include?("render 'turbo_turbo/flashes'") || content.include?('render "turbo_turbo/flashes"')
          content = content.gsub(/(<body[^>]*>\s*)/) do
            "#{::Regexp.last_match(1)}  <%= render 'turbo_turbo/flashes' %>\n  "
          end
        end

        unless content.include?("render 'turbo_turbo/modal_background'") || content.include?('render "turbo_turbo/modal_background"')
          content = content.gsub(%r{(.*render ['"]turbo_turbo/flashes['"].*\n\s*)}) do
            "#{::Regexp.last_match(1)}  <%= render 'turbo_turbo/modal_background' %>\n  "
          end
        end

        # Add ModalComponent before closing body tag if not present
        unless content.include?("TurboTurbo::ModalComponent")
          content = content.gsub(%r{(\s*)</body>}) do
            "#{::Regexp.last_match(1)}  <%= render TurboTurbo::ModalComponent.new %>\n#{::Regexp.last_match(1)}</body>"
          end
        end

        content
      end

      def modify_slim_layout(content)
        # Add turbo-turbo--modal to data-controller if not present
        if content.match?(/data-controller\s*=\s*["'][^"']*["']/)
          # data-controller exists, check if turbo-turbo--modal is present
          unless content.match?(/data-controller\s*=\s*["'][^"']*\bturbo-turbo--modal\b[^"']*["']/)
            content = content.gsub(/(data-controller\s*=\s*["'])([^"']*)(['"])/) do
              prefix = ::Regexp.last_match(1)
              controller_list = ::Regexp.last_match(2)
              suffix = ::Regexp.last_match(3)
              controllers = controller_list.strip.split(/\s+/)
              controllers << "turbo-turbo--modal" unless controllers.include?("turbo-turbo--modal")
              "#{prefix}#{controllers.join(' ')}#{suffix}"
            end
          end
        else
          # Add data-controller with turbo-turbo--modal to body tag
          content = content.gsub(/(^ *body(?:\.[a-zA-Z0-9_-]+)*)\s*$/m) do
            body_line = ::Regexp.last_match(1)
            "#{body_line} data-controller=\"turbo-turbo--modal\""
          end
        end

        # Add layout renders after body tag if not present
        unless content.match?(%r{render\s+["']turbo_turbo/flashes["']}) || content.match?(%r{render\s+"turbo_turbo/flashes"})
          content = content.gsub(/(^ *body(?:\.[a-zA-Z0-9_-]+)*.*\n)/m) do
            "#{::Regexp.last_match(1)}  = render \"turbo_turbo/flashes\"\n"
          end
        end

        unless content.match?(%r{render\s+["']turbo_turbo/modal_background["']}) || content.match?(%r{render\s+"turbo_turbo/modal_background"})
          content = content.gsub(%r{(.*render\s+["']turbo_turbo/flashes["'].*\n)}) do
            "#{::Regexp.last_match(1)}  = render \"turbo_turbo/modal_background\"\n"
          end
        end

        # Add TurboTurbo::ModalComponent at end of body if not present
        unless content.include?("TurboTurbo::ModalComponent")
          # Find the last line with content before implicit body closing
          lines = content.split("\n")
          body_found = false
          insert_index = -1

          lines.each_with_index do |line, index|
            if line.match?(/^\s*body/)
              body_found = true
            elsif body_found && line.strip.length.positive? && !line.match?(%r{^\s*/}) # not a comment
              insert_index = index
            end
          end

          if insert_index >= 0
            lines.insert(insert_index + 1, "  = render TurboTurbo::ModalComponent.new")
            content = lines.join("\n")
          end
        end

        content
      end
    end
  end
end
