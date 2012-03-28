require_relative 'asset'

module SimpleS3Deploy

  def self.deploy(site_path)
    Site.new(site_path).deploy
  end

  class Site
    attr_accessor :path
    attr_accessor :tmp_files

    def initialize(path)
      @path = path
      @tmp_files = []
    end

    def deploy
      puts " ** Deploying #{path} to #{bucket.key}"
      puts " ========================================================"
      puts " ** Deleting existing remote files"
      clear_bucket
      puts " ** Uploading files"
      files.each do |file|
        if !File.directory?(file.path)
          remote_file_name = file_base_path(file.path)
          puts "      Uploading #{remote_file_name} .."
          bucket.files.create(
            key: remote_file_name,
            body: file.minifyable? ? open(minify(file.path)) : open(file.path),
            public: true,
            content_type: file.mime_type,
            cache_control: 'max-age=604800, public' )
        end
      end
      if tmp_files.any?
        puts " ** Cleaning up tmp files"
        cleanup
      end
      puts "\n ** Done"
    end

  private

    def clear_bucket
      bucket.files.each do |f|
        puts "      Deleting #{f.key}"
        f.destroy
      end
    end

    def cleanup
      tmp_files.each do |file|
        puts "      Deleting #{file}"
        File.unlink(file)
      end
    end

    def files
      @files ||= Dir.glob("#{path}/**/*").map { |f| SiteFile.new(f) }
    end

    def file_base_path(file)
      file.gsub("#{path}/", "")
    end

    def minify(file_path)
      "#{file_path}-tmp".tap do |tmp_file_name|
        `yuicompressor -o #{tmp_file_name} #{file_path}`
        tmp_files << tmp_file_name
      end
    end

    def config
      @config ||= YAML.load_file('config.yaml')
    end

    def s3
      @s3 ||= Fog::Storage.new({
        provider: 'AWS',
        aws_secret_access_key: config['s3']['secret_access_key'],
        aws_access_key_id: config['s3']['access_key_id'] })
    end

    def bucket
      @bucket ||= s3.directories.get(config['s3']['bucket'])
    end

  end

  class SiteFile
    include Asset

    def css_file?
      extension == '.css'
    end

    def js_file?
      extension == '.js'
    end

    def minifyable?
      css_file? || js_file?
    end

  end

end
