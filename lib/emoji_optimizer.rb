require 'digest/md5'
require 'tmpdir'

module Emoji

  def self.tmp_dir
    @tmp_dir ||= Dir.mktmpdir 'emoji-optimization'
  end

  class Optimizer

    def initialize options = {}
      @size    = options.delete(:size) { 22 }
      @padding = options.delete(:padding) { 5 }
      @source = Source.new 'public/index.html'
      @sprite = Sprite.new sprite_path, @source.emoji_paths, size: @size, padding: @padding
    end

    def optimize! &block
      puts " ** Preparing for optimization"
      prepare

      puts " ** Generating emoji sprite image"
      if @sprite.generate
        generate_and_save
      else
        puts " ** Could not generate emoji sprite =("
      end

      yield

    ensure
      puts " ** Cleaning up after optimization"
      cleanup
    end

    private

    def prepare
      FileUtils.cp 'public/index.html', File.join(Emoji.tmp_dir, 'index.html')
      FileUtils.cp 'public/emoji.css',  File.join(Emoji.tmp_dir, 'emoji.css')
    end

    def generate_and_save
      puts " ** Generating css and updating markup"

      update_source_markup

      File.open('public/emoji.css', 'a') do |f|
        f.puts @sprite.css_rules.join("\n")
      end
      File.open('public/index.html','w') { |f| f.write @source.to_html }
    end

    def cleanup
      FileUtils.mv File.join(Emoji.tmp_dir, 'index.html'), 'public/index.html'
      FileUtils.mv File.join(Emoji.tmp_dir, 'emoji.css'),  'public/emoji.css'
      FileUtils.rm "public/graphics/#{filename}"
    end

    def update_source_markup
      @source.emojis.each_with_index do |img, index|
        img.replace @source.create_element 'span', {
          'id' => "e_#{index+1}",
          'class' => 'emoji',
          'data-src' => img['src']
        }
      end
    end

    def sprite_path
      @sprite_path ||= "public/graphics/#{filename}"
    end

    def filename
      'sprite.png'
    end

  end

  class Source
    attr_writer :html_source

    def initialize content
      @content = content
    end

    def emojis
      @emojis ||= images.find_all { |img| img['src'] =~ /emojis/ }
    end

    def emoji_paths
      @emoji_paths ||= emojis.map { |img| File.join 'public', img['src'] }
    end

    def create_element *args
      doc.create_element *args
    end

    def to_html
      doc.to_html
    end

    def images
      doc.css 'img'
    end

    def doc
      @doc ||= Nokogiri::HTML html_source.call @content
    end

    def html_source
      @html_source ||= File.public_method :open
    end

  end

  class Sprite
    attr_reader :filename, :files,
                :size, :padding, :options

    def initialize filename, files, options = {}
      @filename = filename
      @files    = files
      @size     = options.delete(:size) { 22 }
      @padding  = options.delete(:padding) { 5 }
      @options  = Options.new({
        tile:       'x1',
        geometry:   "#{size}x#{size}+#{padding}",
        depth:      '8',
        background: 'transparent',
        sharpen:    '0x1.5'
      }.merge(options))
    end

    def offset index
      (size + padding * 2) * index + padding
    end

    def generate path = nil
      path = filename unless path
      result = system "montage %s %s %s" % [ files.join(' '), options, path ]
      optimize! path

      result
    end

    def css_rules
      [].tap do |rules|
        rules << %Q{
          .emoji {
            display:inline-block;
            width:#{@size}px;
            height:#{@size}px;
            background:transparent url(graphics/#{File.basename(filename)}) 0 0 no-repeat;
          }
        }
        files.size.times do |index|
          rules << css_file_mapping(index)
        end
      end
    end

    def css_file_mapping index
      "#e_#{index+1} { background-position:-#{offset index}px 0; }"
    end

    class Options
      extend Forwardable

      def_delegators :@options, :[], :[]=, :map, :each

      def initialize options
        @options = options
      end

      def to_s
        map { |k, v| "-#{k} #{v}" }.join ' '
      end
    end

    private

    def optimize! path
      puts "Checking for png optimizer"
      if system "which optipng"
        puts "Optimizing generated png"
        system "optipng -o5 #{path}"
      else
        puts "No optimization of generated sprite will be done. Install optipng if you want it."
      end
    end

  end
end
