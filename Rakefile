require 'rubygems'
require 'bundler'
Bundler.require
require_relative 'lib/simple_s3_deploy'
require_relative 'lib/emoji_optimizer'

task :deploy do
  EmojiOptimizer.new(:size => 22, :padding => 5).optimize! do
    SimpleS3Deploy.deploy('public')
  end
end
