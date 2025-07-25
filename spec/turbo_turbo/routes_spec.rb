# frozen_string_literal: true

require "spec_helper"

RSpec.describe "TurboTurbo Routes" do
  it "loads turbo_turbo_routes successfully" do
    expect { Rails.application.routes.draw { draw(:turbo_turbo_routes) } }.not_to raise_error
  end

  it "routes file exists at expected location" do
    routes_file = Rails.root.join("config", "routes", "turbo_turbo_routes.rb")
    expect(File.exist?(routes_file)).to be true
  end

  it "defines proper namespace structure in routes file" do
    routes_file = Rails.root.join("config", "routes", "turbo_turbo_routes.rb")
    content = File.read(routes_file)
    
    expect(content).to include("namespace :turbo_turbo")
    expect(content).to include("namespace :admin")
    expect(content).to include("namespace :provider")
  end
end