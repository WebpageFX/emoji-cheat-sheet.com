require_relative 'spec_helper'
require_relative '../lib/simple_s3_deploy'

class AFile
  include SimpleS3Deploy::Asset
end

describe SimpleS3Deploy::Asset do

  subject { AFile.new '/a/path/styles.css' }

  it 'has a filename' do
    subject.filename.must_equal 'styles.css'
  end

  it 'has a extension' do
    subject.extension.must_equal '.css'
  end

  it 'looks up its mime type' do
    MIME::Types.expects(:type_for).with(subject.path).returns ['lol/file']
    subject.mime_type.must_equal 'lol/file'
  end

end

