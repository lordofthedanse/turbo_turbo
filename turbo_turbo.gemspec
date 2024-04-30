# frozen_string_literal: true

require_relative "lib/turbo_turbo/version"

Gem::Specification.new do |spec|
  spec.name = "turbo_turbo"
  spec.version = TurboTurbo::VERSION
  spec.authors = ["Dan Brown"]
  spec.email = ["dbrown@occameducation.com"]

  spec.summary = "A library that aims to speed up using Turbo in common Rails controller actions."
  spec.description = "A simplified DSL for responding in common ways to common controller actions so you can write as little code in CRUD routes as possible."
  spec.homepage = "https://github.com/lordofthedanse/turbo_turbo"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["allowed_push_host"] = "https://github.com/lordofthedanse/turbo_turbo"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/lordofthedanse/turbo_turbo"
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
