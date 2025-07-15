# frozen_string_literal: true

module TurboTurbo
  module TestHelpers
    # Submit a TurboTurbo modal form
    def submit_modal
      button = find("button[data-action='turbo-turbo--modal#submitForm']")
      button.click
    end

    # Click a new button for a given resource type
    def click_new_button(singular_resource)
      find("#new_#{singular_resource}").click
    end

    # Get the DOM ID selector for a table row
    def table_row(resource)
      "##{dom_id(resource)}"
    end

    # Click on a row action link (edit, delete, etc.)
    def click_on_row_link(resource, action_type, confirm: false)
      within table_row(resource) do
        if confirm
          accept_confirm { find("a.#{action_type}_button").click }
        else
          find("a.#{action_type}_button").click
        end
      end
    end

    # Close a TurboTurbo modal
    def close_modal
      # Try to find and click the close button, but don't fail if it's not there
      close_button = "button[data-action='turbo-turbo--modal#closeModal']"

      if page.has_css?(close_button, visible: true)
        find(close_button, match: :first).click
      else
        # If no close button, try clicking the backdrop to close
        backdrop = '.ModalBackdrop-turbo-turbo'
        return true unless page.has_css?(backdrop, visible: true)

        find(backdrop).click

        # If still no modal elements, it might already be closed

      end

      # Wait for modal to close
      expect(page).not_to have_css('[data-turbo-turbo--modal-target="modal"]', visible: true)
    end

    # Check if modal is open
    def modal_open?
      page.has_css?('[data-turbo-turbo--modal-target="modal"]', visible: true)
    end

    # Check if modal is closed
    def modal_closed?
      page.has_no_css?('[data-turbo-turbo--modal-target="modal"]', visible: true)
    end
  end
end
