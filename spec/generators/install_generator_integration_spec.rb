# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe "TurboTurbo Install Generator Integration" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:app_views_dir) { File.join(temp_dir, "app", "views", "layouts") }
  let(:erb_layout_file) { File.join(app_views_dir, "application.html.erb") }
  let(:slim_layout_file) { File.join(app_views_dir, "application.html.slim") }

  before do
    FileUtils.mkdir_p(app_views_dir)
    # Change to temp directory for generator execution
    @original_dir = Dir.pwd
    Dir.chdir(temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(temp_dir)
  end

  # Test class that includes the actual generator logic
  class TestGenerator
    def modify_layout_file
      layout_files = [
        "app/views/layouts/application.html.erb",
        "app/views/layouts/application.html.slim"
      ]

      layout_file = layout_files.find { |file| File.exist?(file) }

      return unless layout_file

      content = File.read(layout_file)
      original_content = content.dup

      content = if layout_file.end_with?(".slim")
                  modify_slim_layout(content)
                else
                  modify_erb_layout(content)
                end

      if content == original_content
        { modified: false, file: layout_file }
      else
        File.write(layout_file, content)
        { modified: true, file: layout_file }
      end
    end

    def add_css_import
      copy_css_file_to_app
      add_css_import_to_main_file
    end

    def copy_css_file_to_app
      # Copy the TurboTurbo CSS files from the gem to the app
      gem_css_dir = File.join(gem_root, "app/assets/stylesheets")
      app_css_dir = "app/assets/stylesheets"

      # CSS subdirectory (now contains base.css and component CSS files)
      gem_css_subdir = File.join(gem_css_dir, "turbo_turbo")
      app_css_subdir = File.join(app_css_dir, "turbo_turbo")

      return unless File.exist?(gem_css_subdir)
      return if File.exist?(app_css_subdir)

      # Copy CSS subdirectory (contains base.css and component files)
      FileUtils.cp_r(gem_css_subdir, app_css_subdir)
    end

    def add_css_import_to_main_file
      css_files = [
        "app/assets/stylesheets/application.tailwind.css",
        "app/assets/stylesheets/application.css"
      ]

      css_file = css_files.find { |file| File.exist?(file) }
      return unless css_file

      content = File.read(css_file)

      # Check if import already exists
      if content.include?('@import "turbo_turbo"') || content.include?('@import "./turbo_turbo"') || content.include?('@import "./turbo_turbo.css"') || content.include?('@import "./turbo_turbo/base"')
        return
      end

      # Add import at the top of the file
      content = "@import \"./turbo_turbo/base\";\n\n#{content}"
      File.write(css_file, content)
    end

    def gem_root
      @gem_root ||= File.expand_path("../../..", __dir__)
    end

    private

    def modify_erb_layout(content)
      # Add modal to data-controller if not present
      if content.match?(/data-controller\s*=\s*["'][^"']*["']/)
        # data-controller exists, check if modal is present
        unless content.match?(/data-controller\s*=\s*["'][^"']*\bmodal\b[^"']*["']/)
          content = content.gsub(/(data-controller\s*=\s*["'])([^"']*)(["'])/) do
            prefix = ::Regexp.last_match(1)
            controller_list = ::Regexp.last_match(2)
            suffix = ::Regexp.last_match(3)
            controllers = controller_list.strip.split(/\s+/)
            controllers << "modal" unless controllers.include?("modal")
            "#{prefix}#{controllers.join(' ')}#{suffix}"
          end
        end
      else
        # Add data-controller with modal to body tag
        content = content.gsub(/(<body[^>]*?)>/) do
          body_tag = ::Regexp.last_match(1)
          "#{body_tag} data-controller=\"modal\">"
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
      unless content.include?("ModalComponent")
        content = content.gsub(%r{(\s*)</body>}) do
          "#{::Regexp.last_match(1)}  <%= render TurboTurbo::ModalComponent.new %>\n#{::Regexp.last_match(1)}</body>"
        end
      end

      content
    end

    def modify_slim_layout(content)
      # Add modal to data-controller if not present
      if content.match?(/data-controller\s*=\s*["'][^"']*["']/)
        # data-controller exists, check if modal is present
        unless content.match?(/data-controller\s*=\s*["'][^"']*\bmodal\b[^"']*["']/)
          content = content.gsub(/(data-controller\s*=\s*["'])([^"']*)(["'])/) do
            prefix = ::Regexp.last_match(1)
            controller_list = ::Regexp.last_match(2)
            suffix = ::Regexp.last_match(3)
            controllers = controller_list.strip.split(/\s+/)
            controllers << "modal" unless controllers.include?("modal")
            "#{prefix}#{controllers.join(' ')}#{suffix}"
          end
        end
      else
        # Add data-controller with modal to body tag
        content = content.gsub(/(^ *body(?:\.[a-zA-Z0-9_-]+)*)\s*$/m) do
          body_line = ::Regexp.last_match(1)
          "#{body_line} data-controller=\"modal\""
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

      # Add ModalComponent at end of body if not present
      unless content.include?("ModalComponent")
        # Find the last line with content before implicit body closing
        lines = content.split("\n")
        body_found = false
        insert_index = -1

        lines.each_with_index do |line, index|
          if line.match?(/^\s*body/)
            body_found = true
          elsif body_found && !line.strip.empty? && !line.match?(%r{^\s*/}) # not a comment
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

  let(:generator) { TestGenerator.new }

  describe "ERB layout modification" do
    context "with no existing data-controller" do
      it "adds modal controller and all components" do
        File.write(erb_layout_file, <<~ERB)
          <!DOCTYPE html>
          <html>
            <head>
              <title>Test App</title>
            </head>
            <body>
              <%= yield %>
            </body>
          </html>
        ERB

        result = generator.modify_layout_file

        expect(result[:modified]).to be true

        modified_content = File.read(erb_layout_file)
        expect(modified_content).to include('data-controller="modal"')
        expect(modified_content).to include("<%= render 'turbo_turbo/flashes' %>")
        expect(modified_content).to include("<%= render 'turbo_turbo/modal_background' %>")
        expect(modified_content).to include("<%= render TurboTurbo::ModalComponent.new %>")
      end
    end

    context "with existing data-controller" do
      it "adds modal to existing controllers" do
        File.write(erb_layout_file, <<~ERB)
          <!DOCTYPE html>
          <html>
            <body data-controller="navigation search">
              <%= yield %>
            </body>
          </html>
        ERB

        result = generator.modify_layout_file

        expect(result[:modified]).to be true

        modified_content = File.read(erb_layout_file)
        expect(modified_content).to include('data-controller="navigation search modal"')
      end
    end

    context "when modal already exists" do
      it "doesn't modify the file" do
        original_content = <<~ERB
          <!DOCTYPE html>
          <html>
            <body data-controller="navigation modal search">
              <%= render 'turbo_turbo/flashes' %>
              <%= render 'turbo_turbo/modal_background' %>
              <%= yield %>
              <%= render TurboTurbo::ModalComponent.new %>
            </body>
          </html>
        ERB

        File.write(erb_layout_file, original_content)

        result = generator.modify_layout_file

        expect(result[:modified]).to be false

        modified_content = File.read(erb_layout_file)
        expect(modified_content).to eq(original_content)
      end
    end
  end

  describe "Slim layout modification" do
    context "with no existing data-controller" do
      it "adds modal controller and all components" do
        File.write(slim_layout_file, <<~SLIM)
          doctype html
          html
            head
              title Test App
            body
              = yield
        SLIM

        result = generator.modify_layout_file

        expect(result[:modified]).to be true

        modified_content = File.read(slim_layout_file)
        expect(modified_content).to include('body data-controller="modal"')
        expect(modified_content).to include('= render "turbo_turbo/flashes"')
        expect(modified_content).to include('= render "turbo_turbo/modal_background"')
        expect(modified_content).to include("= render TurboTurbo::ModalComponent.new")
      end
    end

    context "with CSS classes on body" do
      it "preserves classes and adds data-controller" do
        File.write(slim_layout_file, <<~SLIM)
          doctype html
          html.h-full
            body.h-full.bg-gray-50
              = yield
        SLIM

        result = generator.modify_layout_file

        expect(result[:modified]).to be true

        modified_content = File.read(slim_layout_file)
        expect(modified_content).to include('body.h-full.bg-gray-50 data-controller="modal"')
      end
    end
  end

  describe "layout file detection" do
    context "when both ERB and Slim exist" do
      it "prefers ERB layout" do
        File.write(erb_layout_file, "<body><%= yield %></body>")
        File.write(slim_layout_file, 'body\n  = yield')

        result = generator.modify_layout_file

        expect(result[:file]).to eq("app/views/layouts/application.html.erb")
      end
    end

    context "when no layout file exists" do
      it "returns nil" do
        result = generator.modify_layout_file

        expect(result).to be_nil
      end
    end

    context "when only Slim exists" do
      it "uses Slim layout" do
        File.write(slim_layout_file, 'body\n  = yield')

        result = generator.modify_layout_file

        expect(result[:file]).to eq("app/views/layouts/application.html.slim")
      end
    end
  end

  describe "CSS file copying and import" do
    let(:main_css_file) { "app/assets/stylesheets/application.tailwind.css" }

    before do
      # Create the main CSS file
      FileUtils.mkdir_p("app/assets/stylesheets")
      File.write(main_css_file, "@tailwind base;\n@tailwind components;\n@tailwind utilities;")

      # Create the source CSS files that the gem would have
      gem_css_dir = File.join(File.expand_path("../../..", __dir__), "app/assets/stylesheets")
      gem_css_subdir = File.join(gem_css_dir, "turbo_turbo")

      FileUtils.mkdir_p(gem_css_dir)
      FileUtils.mkdir_p(gem_css_subdir)

      # Create base.css file in subdirectory
      unless File.exist?(File.join(gem_css_subdir, "base.css"))
        File.write(File.join(gem_css_subdir, "base.css"), "/* TurboTurbo CSS */")
      end

      # Create component CSS files
      unless File.exist?(File.join(gem_css_subdir, "alerts.css"))
        File.write(File.join(gem_css_subdir, "alerts.css"), "/* Alerts CSS */")
      end
      unless File.exist?(File.join(gem_css_subdir, "button.css"))
        File.write(File.join(gem_css_subdir, "button.css"), "/* Button CSS */")
      end
      unless File.exist?(File.join(gem_css_subdir, "modal.css"))
        File.write(File.join(gem_css_subdir, "modal.css"), "/* Modal CSS */")
      end
    end

    after do
      FileUtils.rm_rf("app/assets/stylesheets/turbo_turbo")
      FileUtils.rm_f(main_css_file)
    end

    it "copies CSS file and adds import" do
      generator.add_css_import

      # Check that the CSS subdirectory was copied
      expect(File.exist?("app/assets/stylesheets/turbo_turbo")).to be true
      expect(File.exist?("app/assets/stylesheets/turbo_turbo/base.css")).to be true
      expect(File.exist?("app/assets/stylesheets/turbo_turbo/alerts.css")).to be true
      expect(File.exist?("app/assets/stylesheets/turbo_turbo/button.css")).to be true
      expect(File.exist?("app/assets/stylesheets/turbo_turbo/modal.css")).to be true

      # Check that the import was added
      main_css_content = File.read(main_css_file)
      expect(main_css_content).to include('@import "./turbo_turbo/base";')
    end

    it "doesn't copy CSS file if it already exists" do
      # Pre-create the CSS subdirectory
      FileUtils.mkdir_p("app/assets/stylesheets/turbo_turbo")
      File.write("app/assets/stylesheets/turbo_turbo/base.css", "/* existing base content */")
      File.write("app/assets/stylesheets/turbo_turbo/alerts.css", "/* existing alerts */")

      generator.add_css_import

      # Check that the existing content is preserved
      base_content = File.read("app/assets/stylesheets/turbo_turbo/base.css")
      expect(base_content).to eq("/* existing base content */")

      # Check that subdirectory content is preserved
      alerts_content = File.read("app/assets/stylesheets/turbo_turbo/alerts.css")
      expect(alerts_content).to eq("/* existing alerts */")
    end

    it "doesn't add import if it already exists" do
      # Pre-add the import
      File.write(main_css_file, '@import "./turbo_turbo/base";\n@tailwind base;')

      generator.add_css_import

      # Check that the import wasn't duplicated
      content = File.read(main_css_file)
      expect(content.scan(%r{@import "\./turbo_turbo/base"}).length).to eq(1)
    end
  end
end
