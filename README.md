# TurboTurbo

A simplified DSL for responding in common ways to common controller actions so you can write as little code in CRUD routes as possible. TurboTurbo provides a set of controller helpers that streamline Turbo Stream responses, modal management, and flash message handling in Rails applications.

## Features

- **Convention-based DSL** - Eliminate CRUD boilerplate with `turbo_actions :create, :update, :destroy`
- **Modal form abstraction** - Transform 10+ lines of form boilerplate into 3 lines
- **Smart parameter sanitization** - Automatic boolean conversion and string trimming with `sanitize_for_model`
- **Simplified Turbo Stream responses** - Standardized patterns for all CRUD operations
- **Modal management** - Complete modal system with namespaced Stimulus controllers
- **Flash message handling** - Automatic flash message generation with I18n support
- **ViewComponent integration** - Pre-built alert and modal components
- **Configurable action groups** - Customize Turbo Stream behaviors by action type
- **Rails 7+ compatible** - Built for modern Rails applications
- **Zero dependencies** - No external template engines or SVG processors required
- **Test helpers included** - Built-in helpers for system/integration testing

## Quick Start

### 1. Installation

Add this line to your application's Gemfile:

```ruby
gem 'turbo_turbo'
```

And then execute:

```bash
bundle install
rails generate turbo_turbo:install
```

**⚠️ Important: Restart your Rails server after installation for the gem's helpers to be available.**

### 2. Start using the DSL

```ruby
class MessagesController < ApplicationController
  turbo_actions :create, :update, :destroy, :show, :new, :edit

  private

  def message_params
    params.require(:message)
          .permit(:content, :title)
          .sanitize_for_model(:message)
  end
end
```

## What the Installer Does

The installer automatically:
- **Copies namespaced JavaScript controllers** to `app/javascript/controllers/turbo_turbo/`
- **Registers controllers** (`turbo-turbo--modal`, `turbo-turbo--flash`) in Stimulus index.js
- **Configures ApplicationController** with `TurboTurbo::ControllerHelpers` and flash types
- **Copies TurboTurbo CSS** to `app/assets/stylesheets/turbo_turbo/` (includes component CSS files and base.css, which just imports the component CSS files)
- **Imports TurboTurbo CSS** into your main stylesheet
- **Copies layout partials** for modal background and flashes to `app/views/turbo_turbo/`
- **Intelligently modifies your layout file** to include required components
- **ViewComponents work directly from the gem** (no copying required)

### Automatic Layout Setup

The installer automatically modifies your `app/views/layouts/application.html.erb` or `application.html.slim` to:

✅ **Add `turbo-turbo--modal` controller** to existing `data-controller` attribute, or create it if missing  
✅ **Insert flash messages render** after the body tag  
✅ **Insert modal background render** after flashes  
✅ **Append TurboTurbo::ModalComponent** at the end of the body  
✅ **Configure ApplicationController** with TurboTurbo helpers and flash types  
✅ **Copy TurboTurbo CSS** to `app/assets/stylesheets/turbo_turbo/` (all CSS files)
✅ **Import TurboTurbo CSS** into your main stylesheet  

**Before:**
```erb
<body data-controller="navigation search">
  <%= yield %>
</body>
```

**After installation:**
```erb
<body data-controller="navigation search turbo-turbo--modal">
  <%= render 'turbo_turbo/flashes' %>
  <%= render 'turbo_turbo/modal_background' %>
  <%= yield %>
  <%= render TurboTurbo::ModalComponent.new %>
</body>
```

### Custom Layout Installation

For custom layouts (admin, dashboard, etc.):

```bash
# Basic usage - adds all components to admin layout
rails generate turbo_turbo:layout admin

# Skip flash-related components only
rails generate turbo_turbo:layout admin --skip-flash

# Skip modal-related components only  
rails generate turbo_turbo:layout admin --skip-modal

# Skip everything - prints warning and exits
rails generate turbo_turbo:layout admin --skip-flash --skip-modal
```

## Core Features

### 1. Convention-Based DSL

**Before (traditional approach):**
```ruby
class MessagesController < ApplicationController
  def create
    @message = Message.new(message_params)
    process_turbo_response(@message, @message.save)
  end

  def update
    @message = Message.find(params[:id])
    process_turbo_response(@message, @message.update(message_params))
  end

  def destroy
    @message = Message.find(params[:id])
    process_turbo_response(@message, @message.destroy)
  end

  # ... more CRUD actions
end
```

**After (with TurboTurbo DSL):**
```ruby
class MessagesController < ApplicationController
  turbo_actions :create, :update, :destroy, :show, :new, :edit

  private

  def message_params
    params.require(:message).permit(:content, :title)
  end
end
```

**Supported Actions:**
- `:create` - Creates new model instance and calls `process_turbo_response`
- `:update` - Finds and updates model instance
- `:destroy` - Finds and destroys model instance  
- `:show` - Finds model instance and renders modal
- `:new` - Creates new model instance and renders modal
- `:edit` - Finds model instance and renders modal

**Requirements:**
- Controller must follow Rails naming conventions (`MessagesController` → `Message` model)
- Must define a params method (e.g., `message_params`)
- Works with any model that responds to `save`, `update`, and `destroy`

**Advanced Customization:**
```ruby
class MessagesController < ApplicationController
  turbo_actions :create, :update, :destroy

  private

  # Custom params for create vs update
  def create_params
    params.require(:message).permit(:content, :title, :author_id)
  end

  def message_params
    params.require(:message).permit(:content, :title)
  end

  # Custom eager loading per action
  def model_instance_for_show
    Message.includes(:author, :comments).find(params[:id])
  end
end
```

### 2. Modal Form Abstraction

**Before (what you had to write):**
```erb
<%= simple_form_for service_provider, url: [:admin, service_provider], 
    data: { 
      turbo_turbo__modal_target: "form", 
      action: "turbo:submit-end->turbo-turbo--modal#closeOnSuccess" 
    } do |form| %>
  <div class="ModalContent-turbo-turbo">
    <div id="error_message_turbo_turbo"></div>
    <!-- your form fields -->
  </div>
<% end %>
```

**After (with TurboTurbo form helper):**
```erb
<%= turbo_form_for(service_provider, url: [:admin, service_provider]) do |form| %>
  <!-- just your form fields -->
<% end %>
```

**Form Builder Support:**
```erb
<!-- SimpleForm (default) -->
<%= turbo_form_for(object) do |form| %>
  <%= form.input :name %>
<% end %>

<!-- Rails form_with -->
<%= turbo_form_for(object, builder: :form_with) do |form| %>
  <%= form.text_field :name %>
<% end %>

<!-- Rails form_for -->
<%= turbo_form_for(object, builder: :form_for) do |form| %>
  <%= form.text_field :name %>
<% end %>
```

**Customization Options:**
```erb
<%= turbo_form_for(object,
    url: custom_path,                        # Custom form URL
    data: { custom: "attribute" }            # Additional data attributes
) do |form| %>
  <!-- fields -->
<% end %>
```

**The form helper automatically:**
- Wraps your form in the proper modal structure
- Sets up Turbo Stream integration for modal closing
- Handles error message containers
- Integrates with all major Rails form builders

### 3. Parameter Sanitization

TurboTurbo extends `ActionController::Parameters` with a powerful `sanitize_for_model` method that automatically:

- **Converts boolean fields** from strings (\"true\"/\"false\", \"1\"/\"0\") to actual booleans based on your model schema
- **Trims whitespace** from all string inputs
- **Cleans arrays** by trimming strings and removing empty values

```ruby
class MessagesController < ApplicationController
  private

  def message_params
    params.require(:message)
          .permit(:title, :content, :active, :priority, tags: [])
          .sanitize_for_model(:message)
  end
end
```

**Before sanitization:**
```ruby
params = {
  title: "  My Message  ",
  content: "  Hello world  ",
  active: "true",           # String from HTML form
  priority: "1",            # String from HTML form
  tags: ["  ruby  ", "", "  rails  ", nil]
}
```

**After sanitization:**
```ruby
{
  title: "My Message",      # Trimmed
  content: "Hello world",   # Trimmed
  active: true,             # Converted to boolean
  priority: true,           # Converted to boolean (if priority is boolean column)
  tags: ["ruby", "rails"]   # Trimmed and cleaned
}
```

The method is **model-aware** - it only converts fields that are actually boolean columns in your database schema, leaving other fields (like integer `priority`) unchanged.

### 4. Modal Workflows

Create modal forms that integrate seamlessly with Turbo:

```erb
<!-- Trigger modal with remote content -->
<%= link_to "New Message",
    new_message_path,
    data: {
      action: "turbo-turbo--modal#setRemoteSource",
      url: new_message_path,
      title: "Create New Message",
      subtitle: "Fill out the form below"
    },
    class: "btn btn-primary" %>

<!-- Modal will automatically open and load the form -->
```

For custom behavior, you can still use the helper methods directly:

```ruby
class MessagesController < ApplicationController
  def create
    message = Message.new(message_params)
    process_turbo_response(message, message.save)
  end

  def update
    message = Message.find(params[:id])
    process_turbo_response(message, message.update(message_params))
  end

  def destroy
    message = Message.find(params[:id])
    process_turbo_response(message, message.destroy)
  end
end
```

## ViewComponents

TurboTurbo includes several pre-built ViewComponents that work directly from the gem, all properly namespaced under the `TurboTurbo` module:

### Modal Components

**TurboTurbo::ModalComponent**
- Main modal wrapper component
- Options: `show_close: true/false` - Controls visibility of close button
- Usage: `<%= render TurboTurbo::ModalComponent.new(show_close: true) %>`

**TurboTurbo::ModalFooterComponent**
- Modal footer with cancel button and content area
- Options: `skip_close: true/false`, `close_label: "Custom Cancel Text"`
- Usage: `<%= render TurboTurbo::ModalFooterComponent.new(close_label: "Close") { content } %>`

### Alert Components

TurboTurbo includes pre-styled alert components, all namespaced under `TurboTurbo::Alerts`:

- `TurboTurbo::Alerts::SuccessComponent`
- `TurboTurbo::Alerts::ErrorComponent`
- `TurboTurbo::Alerts::WarningComponent`
- `TurboTurbo::Alerts::InfoComponent`
- `TurboTurbo::Alerts::AlertComponent` (base component)

All alert components support:
- Custom headers and messages
- Array of messages for lists
- Dismissible functionality
- Consistent styling

Example usage:
```erb
<%= render TurboTurbo::Alerts::SuccessComponent.new({ header: "Success!", message: "Operation completed" }) %>
<%= render TurboTurbo::Alerts::ErrorComponent.new({ message: ["Error 1", "Error 2"] }) %>
```

## Customization

### ViewComponents Customization

To customize ViewComponents, copy them to your application:

```bash
rails generate turbo_turbo:views
```

This copies all ViewComponent classes and templates to your `app/components/turbo_turbo/` directory for customization. Components in your app directory will override the gem versions.

### I18n Flash Messages

TurboTurbo supports I18n for flash messages. Add to your locale files:

```yaml
# config/locales/en.yml
en:
  turbo_turbo:
    flash:
      success:
        create: "%{resource} created successfully!"
        destroy: "%{resource} deleted!"
        archive: "%{resource} archived!"
        # Add custom actions...
      error:
        default: "We encountered an error trying to %{action} %{resource}."
```

### Action Groups Configuration

Customize which actions trigger different Turbo Stream behaviors:

```ruby
# In an initializer or controller
TurboTurbo::ControllerHelpers.turbo_response_actions[:remove] << "archive"
TurboTurbo::ControllerHelpers.error_response_actions[:validation_errors] << "upload"
```

Available action groups:
- **turbo_response_actions**: `:prepend`, `:replace`, `:remove`
- **error_response_actions**: `:validation_errors`, `:flash_errors`

## Architecture

### Namespacing

TurboTurbo uses namespaced controllers and CSS to prevent conflicts:

- **Stimulus Controllers**: `turbo-turbo--modal`, `turbo-turbo--flash` (installed to `app/javascript/controllers/turbo_turbo/`)
- **CSS Files**: Served from gem at `turbo_turbo/*.css`
- **ViewComponents**: All namespaced under `TurboTurbo::` and `TurboTurbo::Alerts::`
- **Layout Partials**: Installed to `app/views/turbo_turbo/`
- **No conflicts** with your existing controllers or styles

### Component Architecture

- **Modal Controller**: Added to body tag, manages global modal behavior
- **Flash Controllers**: Added to individual flash messages for auto-fade and dismiss
- **ViewComponents**: Served directly from gem, optionally copyable for customization
- **CSS**: Served from gem asset pipeline, automatically imported

## Development

After checking out the repo, run:

```bash
bundle install
rspec
```

## Test Helpers

TurboTurbo includes test helpers for system/integration testing:

```ruby
# In your system specs
RSpec.describe "Modal functionality", type: :system, js: true do
  include TurboTurbo::TestHelpers

  it "creates a record via modal" do
    visit some_path
    
    click_new_button("user")           # Clicks #new_user button
    fill_in "Name", with: "John"
    submit_modal                       # Submits TurboTurbo modal form
    
    expect(page).to have_content("John")
    expect(modal_closed?).to be true
  end
  
  it "edits a record via modal" do
    user = create(:user)
    visit users_path
    
    click_on_row_link(user, "edit")    # Clicks edit button in user's table row
    fill_in "Name", with: "Jane"
    submit_modal
    
    user.reload
    expect(user.name).to eq("Jane")
  end
end
```

**Available Helpers:**
- `submit_modal` - Submit a TurboTurbo modal form
- `click_new_button(resource)` - Click new button for resource type
- `click_on_row_link(resource, action, confirm: false)` - Click action link in table row
- `close_modal` - Close modal and verify it's closed
- `modal_open?` - Check if modal is currently open
- `modal_closed?` - Check if modal is currently closed
- `table_row(resource)` - Get DOM selector for resource's table row

To install this gem onto your local machine:

```bash
bundle exec rake install
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
