#!/usr/bin/env rake
require 'rubygems'
require 'bundler'
Bundler.require

require 'digest/sha1'

task :deploy do
  Site.new('public').deploy
end

class Site
  attr_accessor :path
  attr_accessor :tmp_files

  def initialize(path)
    @path = path
    @tmp_files = []
  end

  def deploy
    puts " ** Deploying to  #{bucket.name}"
    files.each do |file|
      if !File.directory?(file)
        remote_file_name = base_path(file)
        puts "    Uploading #{remote_file_name}"
        S3::Object.send(:new, bucket, {
          key: remote_file_name,
          etag: Digest::SHA256.file(file).hexdigest,
          cache_control: 'max-age=86400, public',
          mime_type: mime_type_for_file(file),
        }).tap do |_object|
          if is_css_file?(file)
            _object.content = open(minify_css_file(file))
          else
            _object.content = open(file)
          end
          _object.save
        end
      end
    end
  end

private

  def mime_type_for_file(file)
    Wand.wave(file)
  end

  def files
    @files ||= Dir.glob("#{path}/**/*")
  end

  def base_path(file)
    file.gsub("#{path}/", "")
  end

  def is_css_file?(file)
    file.end_with?('.css')
  end

  def minify_css_file(file)
    "#{file}-tmp".tap do |tmp_file_name|
      `yuicompressor -o #{tmp_file_name} #{file}`
      @tmp_files << tmp_file_name
    end
  end

  def config
    @config ||= YAML.load_file('config.yaml')
  end

  def bucket
    @bucket ||= s3.buckets.find(config['s3']['bucket'])
  end

  def s3
    @s3 ||= S3::Service.new(
      access_key_id: config['s3']['access_key_id'],
      secret_access_key: config['s3']['secret_access_key']
    )
  end
end
