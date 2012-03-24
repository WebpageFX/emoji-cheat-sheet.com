module SimpleS3Deploy

  def self.deploy(site_path)
    Site.new(site_path).deploy
  end

  class Site
    attr_accessor :path
    attr_accessor :tmp_files
    attr_accessor :css_file_name

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
          remote_file_name = file.is_emoji_css? ? generate_css_file_name(file.path) : file_base_path(file.path)
          puts "      Uploading #{remote_file_name} .."
          bucket.files.create(
            key: remote_file_name,
            body: file.should_be_altered? ? alter(file) : open(file.path),
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

    def alter(file)
      if file.is_html_file? and file.path.match('index.html')
        update_css_link
      else
        open(minify(file.path))
      end
    end

    def generate_css_file_name(file_path)
      puts "      Generating hashed css file name .."
      ext = File.extname(file_path)
      name = File.basename(file_path,File.extname(file_path))
      hash = Digest::MD5.hexdigest(File.mtime(file_path).to_i.to_s+File.size(file_path).to_s)
      @css_file_name = "#{name}-#{hash}#{ext}"
    end

    def update_css_link
      puts "      Applying hashed css file name to index.html .."
      doc = Nokogiri::HTML File.open("#{path}/index.html")
      doc.at_css('link[@href="/emoji.css"]')['href'] = "/#{@css_file_name}"
      doc.to_html
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
    attr_accessor :path

    def initialize(_path)
      @path = _path
    end

    def is_minifyable?
      is_css_file? or is_js_file?
    end

    def is_css_file?
      path.end_with?('.css')
    end

    def is_js_file?
      path.end_with?('.js')
    end

    def is_html_file?
      path.end_with?('.html')
    end

    def is_emoji_css?
      path.match('emoji.css')
    end

    def should_be_altered?
      is_html_file? or is_css_file? or is_js_file?
    end

    def mime_type
      MIME::Types.type_for(path)[0].to_s
    end

  end

end
