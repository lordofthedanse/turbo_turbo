# frozen_string_literal: true

require 'spec_helper'

# Mock column class for testing
class MockColumn
  attr_reader :type

  def initialize(type)
    @type = type
  end
end

RSpec.describe TurboTurbo::ParameterSanitizer do
  # Mock model for testing
  let(:mock_model) do
    Class.new do
      def self.name
        'User'
      end

      def self.columns_hash
        {
          'name' => MockColumn.new(:string),
          'active' => MockColumn.new(:boolean),
          'admin' => MockColumn.new(:boolean),
          'age' => MockColumn.new(:integer),
          'email' => MockColumn.new(:string),
          'tags' => MockColumn.new(:text)
        }
      end
    end
  end

  let(:params) do
    ActionController::Parameters.new({
                                       name: '  John Doe  ',
                                       active: 'true',
                                       admin: 'false',
                                       age: '25',
                                       email: '  john@example.com  ',
                                       tags: ['  tag1  ', '', '  tag2  ', nil],
                                       bio: ''
                                     })
  end

  before do
    stub_const('User', mock_model)
  end

  describe '#sanitize_for_model' do
    it 'converts boolean fields from strings to actual booleans' do
      result = params.sanitize_for_model(:user)

      expect(result[:active]).to eq(true)
      expect(result[:admin]).to eq(false)
    end

    it 'trims whitespace from string fields' do
      result = params.sanitize_for_model(:user)

      expect(result[:name]).to eq('John Doe')
      expect(result[:email]).to eq('john@example.com')
    end

    it 'leaves non-boolean fields unchanged except for trimming' do
      result = params.sanitize_for_model(:user)

      expect(result[:age]).to eq('25')
      expect(result[:bio]).to eq('')
    end

    it 'cleans arrays by trimming strings and removing empty values' do
      result = params.sanitize_for_model(:user)

      expect(result[:tags]).to eq(%w[tag1 tag2])
    end

    it 'returns self for method chaining' do
      result = params.sanitize_for_model(:user)
      expect(result).to be(params)
    end

    it 'raises error for invalid model key' do
      expect do
        params.sanitize_for_model(:nonexistent_model)
      end.to raise_error(ArgumentError, 'Model could not be deduced from symbol (nonexistent_model)')
    end
  end

  describe '#convert_to_boolean' do
    subject { params }

    it "converts 'true' string to true boolean" do
      expect(subject.send(:convert_to_boolean, 'true')).to eq(true)
    end

    it "converts 'false' string to false boolean" do
      expect(subject.send(:convert_to_boolean, 'false')).to eq(false)
    end

    it "converts '1' string to true boolean" do
      expect(subject.send(:convert_to_boolean, '1')).to eq(true)
    end

    it "converts '0' string to false boolean" do
      expect(subject.send(:convert_to_boolean, '0')).to eq(false)
    end

    it 'leaves other values unchanged' do
      expect(subject.send(:convert_to_boolean, 'other')).to eq('other')
      expect(subject.send(:convert_to_boolean, 42)).to eq(42)
      expect(subject.send(:convert_to_boolean, nil)).to eq(nil)
    end
  end

  describe '#model_from_key' do
    subject { params }

    it 'converts symbol to model class' do
      expect(subject.send(:model_from_key, :user)).to eq(mock_model)
    end

    it 'raises error for non-existent model' do
      expect do
        subject.send(:model_from_key, :nonexistent)
      end.to raise_error(ArgumentError, 'Model could not be deduced from symbol (nonexistent)')
    end
  end

  describe '#trim_input_strings' do
    subject { params }

    it 'trims whitespace from string values' do
      subject.send(:trim_input_strings)
      expect(subject[:name]).to eq('John Doe')
      expect(subject[:email]).to eq('john@example.com')
    end

    it 'trims strings in arrays and removes empty values' do
      subject.send(:trim_input_strings)
      expect(subject[:tags]).to eq(%w[tag1 tag2])
    end

    it "preserves empty strings (doesn't convert to nil)" do
      subject.send(:trim_input_strings)
      expect(subject[:bio]).to eq('')
    end
  end

  describe 'integration with Rails controller params' do
    let(:controller_params) do
      ActionController::Parameters.new({
                                         user: {
                                           name: '  Jane Smith  ',
                                           active: 'true',
                                           admin: '0',
                                           tags: ['  ruby  ', '', '  rails  ']
                                         }
                                       })
    end

    it 'works with standard Rails strong parameters pattern' do
      result = controller_params.require(:user).permit(:name, :active, :admin, tags: []).sanitize_for_model(:user)

      expect(result[:name]).to eq('Jane Smith')
      expect(result[:active]).to eq(true)
      expect(result[:admin]).to eq(false)
      expect(result[:tags]).to eq(%w[ruby rails])
    end
  end
end
