require_relative '../spec_helper'
require_relative '../../lib/emoji_optimizer'

describe Emoji::Sprite::Options do
  let(:options) { Emoji::Sprite::Options.new(tool: 'hammer', size: 'huge', nails: 5) }

  it 'writes values' do
    options[:size] = 'small'
    options[:size].must_equal 'small'
  end

  it 'returns values' do
    options[:tool].must_equal 'hammer'
  end

  describe 'to_s' do
    it 'renders an argument list' do
      options.to_s.must_equal '-tool hammer -size huge -nails 5'
    end
  end
end
