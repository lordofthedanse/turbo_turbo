# frozen_string_literal: true

# TurboTurbo routes for modal-based CRUD operations
# Add `draw(:turbo_turbo_routes)` to your main routes.rb file to include these routes

namespace :turbo_turbo do
  # Admin namespace for administrative modal operations
  namespace :admin do
    # Add your admin resources here
    # Example: resources :pathways, only: [:new, :create, :show, :edit, :update, :destroy]
  end

  # Provider namespace for provider modal operations
  namespace :provider do
    # Add your provider resources here
    # Example: resources :pathways, only: [:new, :create, :show, :edit, :update, :destroy]
  end

  # Add other namespaces as needed
end
