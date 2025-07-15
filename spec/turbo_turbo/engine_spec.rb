# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TurboTurbo::Engine do
  it 'is a Rails engine' do
    expect(TurboTurbo::Engine).to be < Rails::Engine
  end

  it 'has correct namespace' do
    expect(TurboTurbo::Engine.isolated?).to be true
  end
end
