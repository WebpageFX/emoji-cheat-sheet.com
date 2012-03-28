require 'rubygems'
require 'bundler'
Bundler.require
require 'rake/testtask'

require_relative 'lib/emoji_optimizer'
require_relative 'lib/cache_buster'
require_relative 'lib/simple_s3_deploy'

task :deploy do
  Emoji::Optimizer.new(size: 22, padding: 5).optimize! do
    SimpleS3Deploy::CacheBuster.run 'public/index.html' do
      SimpleS3Deploy.deploy 'public'
    end
  end
end

Rake::TestTask.new(:spec) do |t|
  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
end

namespace :test do
  task :deploy do
    path = File.expand_path File.join(__FILE__, '../')

    Emoji::Optimizer.new(size: 22, padding: 5).optimize! do
      SimpleS3Deploy::CacheBuster.run 'public/index.html' do
        puts FileUtils.cp_r File.join(path, 'public'), File.join(path, 'deploy_dry_run')
      end
    end
  end

  task :cache_busting do
    path = File.expand_path File.join(__FILE__, '../')

    SimpleS3Deploy::CacheBuster.run 'public/index.html' do
      puts "Copying public to public_dry_run"
      puts FileUtils.cp_r File.join(path, 'public'), File.join(path, 'cache_busting_dry_run')
    end
  end

  task :sprite do
    path = 'public/graphics/test_sprite.png'

    source = Emoji::Source.new 'public/index.html'
    sprite = Emoji::Sprite.new path, source.emoji_paths, size: 22, padding: 5

    puts "Generating sprite into #{path}"
    sprite.generate
  end
end
