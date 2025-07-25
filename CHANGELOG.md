# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-01-23

### Fixed
- Renamed routes file from `turbo_turbo.rb` to `turbo_turbo_routes.rb` to prevent loading issues
- Updated install generator to use the new routes filename
- Fixed routes configuration to use `draw(:turbo_turbo_routes)` instead of `draw(:turbo_turbo)`

### Added
- Routes spec to ensure routes file loads properly

## [0.1.0] - 2025-01-15

### Added
- Initial release of TurboTurbo gem
- Controller helpers for standardized Turbo Stream responses
- Modal management system with JavaScript controller
- Flash message handling with auto-dismiss functionality
- ViewComponent alert components (Success, Error, Warning, Info, Alert)
- Rails generator for easy installation with automatic configuration
- Complete test suite with RSpec
- Comprehensive documentation and usage examples
- Enhanced install generator with automatic ApplicationController setup
- Automatic CSS import handling
- Custom layout generator for multi-layout applications
- Form helper for standardized modal forms with builder support
- Parameter sanitization with `sanitize_for_model` method
- `turbo_actions` DSL for convention-based CRUD operations
- Test helpers for system and integration testing

### Features
- `process_turbo_response` for handling CRUD operations
- `render_turbo_modal` for modal workflows
- `turbo_success_response` and `turbo_error_response` for custom responses
- `turbo_form_for` form helper with SimpleForm, form_with, and form_for support
- `turbo_actions` DSL supporting :create, :update, :destroy, :show, :new, :edit
- Automatic flash message generation with proper grammar and I18n support
- Modal controller with remote content loading
- Flash controller with fade-out animations
- Parameter sanitization with boolean conversion and string trimming
- Smart install generator that configures ApplicationController and imports CSS
- Rails 7+ compatibility
- Turbo-rails integration
- ViewComponent integration