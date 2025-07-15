# frozen_string_literal: true

require 'rails/generators/base'

module TurboTurbo
  module Generators
    class LayoutGenerator < Rails::Generators::Base
      desc 'Install TurboTurbo components to a custom layout file'
      source_root File.expand_path('templates', __dir__)

      argument :layout_name, type: :string, default: 'application',
                             desc: 'The layout file name (without extension)'

      class_option :skip_flash, type: :boolean, default: false,
                                desc: 'Skip adding flash-related components (flashes render)'

      class_option :skip_modal, type: :boolean, default: false,
                                desc: 'Skip adding modal-related components (data controller, modal background, ModalComponent)'

      def check_if_everything_skipped
        return unless options[:skip_flash] && options[:skip_modal]

        say 'You skipped everything, so we did nothing!', :yellow
        exit(0)
      end

      def ensure_layout_partials_exist
        empty_directory 'app/views/turbo_turbo'

        if !options[:skip_flash] && !File.exist?('app/views/turbo_turbo/_flashes.html.erb')
          copy_file 'turbo_turbo/_flashes.html.erb', 'app/views/turbo_turbo/_flashes.html.erb'
        end

        return if options[:skip_modal]
        return if File.exist?('app/views/turbo_turbo/_modal_background.html.erb')

        copy_file 'turbo_turbo/_modal_background.html.erb', 'app/views/turbo_turbo/_modal_background.html.erb'
      end

      def modify_custom_layout_file
        layout_files = [
          "app/views/layouts/#{layout_name}.html.erb",
          "app/views/layouts/#{layout_name}.html.slim"
        ]

        layout_file = layout_files.find { |file| File.exist?(file) }

        unless layout_file
          say "Error: Could not find layout file for '#{layout_name}'", :red
          say "Looking for: #{layout_files.join(' or ')}", :yellow
          return
        end

        content = File.read(layout_file)
        original_content = content.dup

        content = if layout_file.end_with?('.slim')
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

      def display_completion_message
        say "\nTurboTurbo components added to #{layout_name} layout!", :green
        say "\nComponents added:"

        say '✅ turbo_turbo/flashes render' unless options[:skip_flash]

        unless options[:skip_modal]
          say '✅ turbo-turbo--modal data controller'
          say '✅ turbo_turbo/modal_background render'
          say '✅ TurboTurbo::ModalComponent render'
        end

        return unless options[:skip_flash] || options[:skip_modal]

        say "\nSkipped components:"
        say '⏭️  Flash-related: turbo_turbo/flashes render' if options[:skip_flash]
        return unless options[:skip_modal]

        say '⏭️  Modal-related: data controller, modal background, ModalComponent'
      end

      private

      def modify_erb_layout(content)
        # Add turbo-turbo--modal to data-controller if not present and not skipped
        unless options[:skip_modal]
          if content.match?(/data-controller\s*=\s*["'][^"']*["']/)
            # data-controller exists, check if turbo-turbo--modal is present
            unless content.match?(/data-controller\s*=\s*["'][^"']*\bturbo-turbo--modal\b[^"']*["']/)
              content = content.gsub(/(data-controller\s*=\s*["'])([^"']*)(['"])/) do
                prefix = ::Regexp.last_match(1)
                controller_list = ::Regexp.last_match(2)
                suffix = ::Regexp.last_match(3)
                controllers = controller_list.strip.split(/\s+/)
                controllers << 'turbo-turbo--modal' unless controllers.include?('turbo-turbo--modal')
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
        end

        # Add flashes render after body tag if not present and not skipped
        if !options[:skip_flash] && !(content.include?("render 'turbo_turbo/flashes'") || content.include?('render "turbo_turbo/flashes"'))
          content = content.gsub(/(<body[^>]*>\s*)/) do
            "#{::Regexp.last_match(1)}  <%= render 'turbo_turbo/flashes' %>\n  "
          end
        end

        # Add modal background render if not present and not skipped
        if !options[:skip_modal] && !(content.include?("render 'turbo_turbo/modal_background'") || content.include?('render "turbo_turbo/modal_background"'))
          content = if content.include?("render 'turbo_turbo/flashes'") || content.include?('render "turbo_turbo/flashes"')
                      # Insert after flashes
                      content.gsub(%r{(.*render ['"]turbo_turbo/flashes['"].*\n\s*)}) do
                        "#{::Regexp.last_match(1)}  <%= render 'turbo_turbo/modal_background' %>\n  "
                      end
                    else
                      # Insert after body tag
                      content.gsub(/(<body[^>]*>\s*)/) do
                        "#{::Regexp.last_match(1)}  <%= render 'turbo_turbo/modal_background' %>\n  "
                      end
                    end
        end

        # Add ModalComponent before closing body tag if not present and not skipped
        if !options[:skip_modal] && !content.include?('TurboTurbo::ModalComponent')
          content = content.gsub(%r{(\s*)</body>}) do
            "#{::Regexp.last_match(1)}  <%= render TurboTurbo::ModalComponent.new %>\n#{::Regexp.last_match(1)}</body>"
          end
        end

        content
      end

      def modify_slim_layout(content)
        # Add turbo-turbo--modal to data-controller if not present and not skipped
        unless options[:skip_modal]
          if content.match?(/data-controller\s*=\s*["'][^"']*["']/)
            # data-controller exists, check if turbo-turbo--modal is present
            unless content.match?(/data-controller\s*=\s*["'][^"']*\bturbo-turbo--modal\b[^"']*["']/)
              content = content.gsub(/(data-controller\s*=\s*["'])([^"']*)(['"])/) do
                prefix = ::Regexp.last_match(1)
                controller_list = ::Regexp.last_match(2)
                suffix = ::Regexp.last_match(3)
                controllers = controller_list.strip.split(/\s+/)
                controllers << 'turbo-turbo--modal' unless controllers.include?('turbo-turbo--modal')
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
        end

        # Add flashes render after body tag if not present and not skipped
        if !options[:skip_flash] && !(content.match?(%r{render\s+["']turbo_turbo/flashes["']}) || content.match?(%r{render\s+"turbo_turbo/flashes"}))
          content = content.gsub(/(^ *body(?:\.[a-zA-Z0-9_-]+)*.*\n)/m) do
            "#{::Regexp.last_match(1)}  = render \"turbo_turbo/flashes\"\n"
          end
        end

        # Add modal background render if not present and not skipped
        if !options[:skip_modal] && !(content.match?(%r{render\s+["']turbo_turbo/modal_background["']}) || content.match?(%r{render\s+"turbo_turbo/modal_background"}))
          content = if content.match?(%r{render\s+["']turbo_turbo/flashes["']})
                      # Insert after flashes
                      content.gsub(%r{(.*render\s+["']turbo_turbo/flashes["'].*\n)}) do
                        "#{::Regexp.last_match(1)}  = render \"turbo_turbo/modal_background\"\n"
                      end
                    else
                      # Insert after body tag
                      content.gsub(/(^ *body(?:\.[a-zA-Z0-9_-]+)*.*\n)/m) do
                        "#{::Regexp.last_match(1)}  = render \"turbo_turbo/modal_background\"\n"
                      end
                    end
        end

        # Add TurboTurbo::ModalComponent at end of body if not present and not skipped
        if !options[:skip_modal] && !content.include?('TurboTurbo::ModalComponent')
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
            lines.insert(insert_index + 1, '  = render TurboTurbo::ModalComponent.new')
            content = lines.join("\n")
          end
        end

        content
      end
    end
  end
end
