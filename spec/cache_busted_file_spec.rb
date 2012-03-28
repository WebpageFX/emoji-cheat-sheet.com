require_relative 'spec_helper'
require_relative '../lib/cache_busted_file'

describe SimpleS3Deploy::CacheBustedFile do

  subject do
    path = File.expand_path File.join(__FILE__, '../fixtures/styles.css')
    SimpleS3Deploy::CacheBustedFile.new path
  end

  before :each do
    subject.expects(:read).returns 'zomg'
    subject.stubs(:write).returns true
  end

  describe "digest" do
    let :digest do
      Digest::MD5.hexdigest 'zomg'
    end

    it 'is calculated from the files content' do
      subject.digest.must_equal digest
    end

    it 'is appended to the filename as digested_filename' do
      subject.digested_filename.must_equal "styles_#{digest}.css"
    end
  end

  describe 'renaming' do
    let :digested_filename_path do
      File.join File.dirname(subject.path), subject.digested_filename
    end

    it 'can be renamed to the digested filename' do
      FileUtils.expects(:mv).with subject.path, digested_filename_path

      subject.rename_to_digested_filename

      subject.path.must_equal digested_filename_path
    end

    it 'can be renamed to the original filename' do
      FileUtils.expects(:mv).with digested_filename_path, subject.path

      subject.rename_to_original_filename

      subject.path.must_equal subject.original_path
    end
  end

  it 'stores the original file content' do
    subject.stubs(:write)

    subject.data = 'omg'
    subject.original_data.must_equal 'zomg'
  end

end
