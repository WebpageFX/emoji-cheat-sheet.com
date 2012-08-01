require 'rubygems'
require 'bundler'
Bundler.require
require_relative 'lib/simple_s3_deploy'
require_relative 'lib/emoji_optimizer'

task :deploy do
  Emoji::Optimizer.new(:size => 22, :padding => 5).optimize! do
    SimpleS3Deploy.deploy 'public'
  end
end

namespace :test do
  task :sprite do
    source = Emoji::Source.new 'public/index.html'
    sprite = Emoji::Sprite.new source.emoji_paths, 22, 5
    path = 'public/graphics/test_sprite.png'
    puts "Generating sprite into #{path}"
    sprite.generate path
  end
end
