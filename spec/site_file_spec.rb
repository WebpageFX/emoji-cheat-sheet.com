require_relative 'spec_helper'
require_relative '../lib/simple_s3_deploy'

describe SimpleS3Deploy::SiteFile do

  subject { SimpleS3Deploy::SiteFile.new '/a/path/styles.css' }

  it 'is minifyable if css' do
    file = SimpleS3Deploy::SiteFile.new 'styles.css'
    file.minifyable?.must_equal true
  end

  it 'is minifyable if js' do
    file = SimpleS3Deploy::SiteFile.new 'rules.js'
    file.minifyable?.must_equal true
  end

  it 'is not minifyable if it is a another kind of file' do
    file = SimpleS3Deploy::SiteFile.new 'rules.png'
    file.minifyable?.must_equal false
  end

end
