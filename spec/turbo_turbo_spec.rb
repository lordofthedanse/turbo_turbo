# frozen_string_literal: true

RSpec.describe TurboTurbo do
  it 'has a version number' do
    expect(TurboTurbo::VERSION).not_to be nil
  end

  it 'includes ControllerHelpers module' do
    expect(TurboTurbo::ControllerHelpers).to be_a(Module)
  end

  it 'has an Engine class' do
    expect(TurboTurbo::Engine).to be < Rails::Engine
  end
end
