require_relative 'spec_helper'
require_relative '../lib/cache_buster'

describe SimpleS3Deploy::CacheBuster do
  let :path do
    File.expand_path File.join(__FILE__, '../fixtures')
  end

  subject do
    SimpleS3Deploy::CacheBuster.new File.join(path, 'index.html')
  end

  it 'finds the linked stylesheets' do
    expected_path = File.join path, 'styles.css'
    subject.stylesheets.map { |s| s.path }.must_equal [expected_path]
  end

  it 'finds all images in the linked stylesheets' do
    emoji_directory = File.expand_path File.join(path, 'graphics')

    expected_paths = [
      File.join(emoji_directory, '+1.png'),
      File.join(emoji_directory, '-1.png'),
      File.join(emoji_directory, 'same_name-1.png')
    ]
    subject.images.map { |i| i.path }.must_equal expected_paths
  end

  describe 'run' do
    before :each do
      SimpleS3Deploy::CacheBustedFile.any_instance.stubs :rename_to_digested_filename
      SimpleS3Deploy::CacheBustedFile.any_instance.stubs :write
    end

    it 'renames the images to the digested name' do
      subject.images.each do |img|
        img.expects(:rename_to_digested_filename).once
      end

      subject.run
    end

    it 'updates the image references in the stylesheets' do
      subject.run

      subject.stylesheets.each do |stylesheet|
        digested_stylesheet_data = File.read File.join(File.dirname(stylesheet.path), 'styles_digested.css')
        stylesheet.data.must_equal digested_stylesheet_data
      end
    end

    it 'renames all assets found in the html source' do
      subject.stylesheets.each do |stylesheet|
        stylesheet.expects(:rename_to_digested_filename).once
      end

      subject.run
    end

    # FIXME Duplicated functionality from CacheBuster#find_stylesheets
    it 'updates the asset references in the html source' do
      subject.run

      doc = Nokogiri::HTML subject.file.data
      paths = doc.css('link[rel="stylesheet"]').reject do |link|
        link['href'].start_with? 'http'
      end.map do |link|
        File.basename link['href']
      end

      paths.must_equal [subject.stylesheets.first.digested_filename]
    end
  end

  describe 'cleanup' do
    before :each do
      SimpleS3Deploy::CacheBustedFile.any_instance.stubs :rename_to_digested_filename
      SimpleS3Deploy::CacheBustedFile.any_instance.stubs :rename_to_original_filename
      SimpleS3Deploy::CacheBustedFile.any_instance.stubs :write
      subject.run
    end

    it 'reverts the image filenames' do
      subject.images.each do |img|
        img.expects(:rename_to_original_filename).once
      end

      subject.cleanup
    end

    it 'reverts the stylesheets data' do
      subject.stylesheets.each do |stylesheet|
        stylesheet.expects(:data=).with(stylesheet.original_data).once
      end

      subject.cleanup
    end

    it 'reverts the stylesheets names' do
      subject.stylesheets.each do |stylesheet|
        stylesheet.expects(:rename_to_original_filename).once
      end

      subject.cleanup
    end

    it 'reverts the stylesheet references in html source' do
      subject.cleanup

      doc = Nokogiri::HTML subject.file.data
      filenames = subject.find_stylesheets(doc).map do |stylesheet|
        stylesheet.filename
      end

      filenames.must_equal subject.stylesheets.map { |s| s.original_filename }
    end
  end

  describe "#run" do
    before :each do
      subject.stubs :run
      subject.stubs :cleanup

      SimpleS3Deploy::CacheBuster.stubs(:new).returns subject
    end

    it 'ensures that cleanup is called' do
      subject.expects :cleanup

      proc {
        SimpleS3Deploy::CacheBuster.run File.join(path, 'index.html') do
          raise RuntimeError
        end
      }.must_raise RuntimeError
    end
  end
end
