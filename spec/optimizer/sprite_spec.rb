require_relative '../spec_helper'
require_relative '../../lib/emoji_optimizer'

class Emoji::TestSprite < Emoji::Sprite
  # Log calls to system so we can inspect them in the tests
  attr_reader :system_calls
  def system command
    (@system_calls ||= []) << command
    command
  end

  # Also, be quiet
  def puts message; end
end

describe Emoji::Sprite do
  let :sprite do
    images = ['image1.png', 'image2.png', 'image3.png']
    Emoji::TestSprite.new 'sprite.png', images, size: 10, padding: 2
  end

  it 'calculates the offset' do
    sprite.offset(0).must_equal 2
    sprite.offset(1).must_equal 2 + 10 + 2 + 2
    sprite.offset(2).must_equal 2 + 10 + 2 + 2 + 10 + 2 + 2
  end

  describe 'options' do
    let(:options) { sprite.options }

    it 'is an instance of Options' do
      options.must_be_instance_of Emoji::Sprite::Options
    end

    it 'sets the defaults' do
      options[:tile].must_equal 'x1'
      options[:geometry].must_equal '10x10+2'
      options[:depth].must_equal '8'
      options[:background].must_equal 'transparent'
      options[:sharpen].must_equal '0x1.5'
    end

    it 'allows overriding' do
      s = Emoji::TestSprite.new 'sprite.png', [], tile: 'x2'
      s.options[:tile].must_equal 'x2'
    end
  end

  it 'generates a sprite image with the montage command' do
    files = 'image1.png image2.png image3.png'
    expected_command = "montage #{files} #{sprite.options} sprite.png"

    sprite.generate
    sprite.system_calls[0].must_equal expected_command
  end

  it 'calls optimize! when generating' do
    def sprite.optimize! path
      @optimize_called = true
    end

    sprite.generate
    sprite.instance_variable_get(:@optimize_called).must_equal true
  end

  describe 'sprite optimization' do
    it 'checks if optipng exists' do
      sprite.send :optimize!, 'test.png'
      sprite.system_calls[0].must_equal 'which optipng'
    end

    it 'runs optimization' do
     sprite.send :optimize!, 'test.png'
     sprite.system_calls[1].must_equal 'optipng -o5 test.png'
    end

    it 'does not run optipng unless it exists' do
      def sprite.system(*args)
        super
        false
      end
      sprite.send :optimize!, 'test.png'

      sprite.system_calls.join.must_equal 'which optipng'
    end
  end
end
