require_relative '../spec_helper'
require_relative '../../lib/emoji_optimizer'

describe Emoji::Source do
  let(:source) do
    Emoji::Source.new(HTML_SOURCE).tap do |s|
      s.html_source = ->(str) { str }
    end
  end

  it 'finds all images' do
    expected_image_paths = [
      '/graphics/emojis/angry.png',
      '/graphics/logo.png',
      '/graphics/emojis/cloud.png'
    ]
    actual_image_paths = source.images.map { |e| e['src'] }

    actual_image_paths.must_equal expected_image_paths
  end

  it 'finds only emoji images' do
    expected_image_paths = [
      '/graphics/emojis/angry.png',
      '/graphics/emojis/cloud.png'
    ]
    actual_image_paths = source.emojis.map { |e| e['src'] }

    actual_image_paths.must_equal expected_image_paths
  end

  it 'expands the emoji paths' do
    expected_paths = source.emojis.map { |e| File.join 'public', e['src'] }

    source.emoji_paths.must_equal expected_paths
  end

  it 'has an nokogiri document' do
    source.send(:doc).must_be_instance_of Nokogiri::HTML::Document
  end

  it 'delegates create_element to its doc' do
    mock = mock_doc :create_element, nil, ['span', 'thingy']

    source.create_element 'span', 'thingy'
    assert mock.verify
  end

  it 'delegates to_html to its doc' do
    mock = mock_doc :to_html, HTML_SOURCE

    source.to_html
    assert mock.verify
  end

  private

  def mock_doc(method, returns, *args)
    mock = MiniTest::Mock.new.expect method, returns, *args
    source.instance_variable_set :@doc, mock
    mock
  end
end
