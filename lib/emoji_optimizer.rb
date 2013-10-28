require 'digest/md5'
require 'tmpdir'

module Emoji

  def self.tmp_dir
    @tmp_dir ||= Dir.mktmpdir 'emoji-optimization'
  end

  class Optimizer

    def initialize options = {}
      @size    = options.delete(:size) { 22 }
      @padding = options.delete(:padding) { 2 }
      @source = Source.new 'public/index.html'
      @sprite = Sprite.new @source.emoji_paths, @size, @padding
      @retina_sprite = Sprite.new @source.emoji_paths, @size*2, @padding*2
    end

    def optimize! &block
      puts " ** Preparing for optimization"
      prepare

      puts " ** Generating emoji sprite image #{sprite_path}"
      if @sprite.generate sprite_path
        puts " ** Generating emoji retina sprite image #{retina_sprite_path}"
        @retina_sprite.generate retina_sprite_path
        puts " ** Generating css and updating markup"
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
      FileUtils.cp 'public/style.css',  File.join(Emoji.tmp_dir, 'style.css')
    end

    def generate_and_save
      update_source_markup

      File.open('public/style.css', 'a') { |f| f.puts css_rules.join("\n") }
      File.open('public/index.html','w') { |f| f.write @source.to_html }
      FileUtils.mv sprite_path, "public/graphics/#{digest_name}"
      FileUtils.mv retina_sprite_path, "public/graphics/#{retina_digest_name}"
    end

    def cleanup
      FileUtils.mv File.join(Emoji.tmp_dir, 'index.html'), 'public/index.html'
      FileUtils.mv File.join(Emoji.tmp_dir, 'style.css'),  'public/style.css'
      FileUtils.rm_f "public/graphics/#{@digest_name}"
      FileUtils.rm_f "public/graphics/#{@retina_digest_name}"
    end

    def css_rules
      [].tap do |rules|
        rules << %Q{
          .emoji {
            float:left;
            margin-right:.5em;
            width:#{@size}px;
            height:#{@size}px;
          }
          @media all and (-webkit-min-device-pixel-ratio: 1),
                 all and (min--moz-device-pixel-ratio: 1),
                 all and (-o-min-device-pixel-ratio: 1),
                 all and (min-device-pixel-ratio: 1),
                 all and (min-resolution: 96dpi) {
            .emoji {
              background:transparent url(/graphics/#{digest_name}) 0 0 no-repeat;
            }
          }
          @media all and (-webkit-min-device-pixel-ratio: 1.5),
                 all and (-o-min-device-pixel-ratio: 3/2),
                 all and (min-device-pixel-ratio: 1.5),
                 all and (min-resolution: 144dpi) {
            .emoji {
              background:transparent url(/graphics/#{retina_digest_name}) 0 0 no-repeat;
              background-size: #{(@size+@padding*2)*@source.emoji_paths.size}px #{@size}px;
            }
          }
          @-moz-document url-prefix() {
            .emoji {
              background:transparent url(/graphics/#{digest_name}) 0 0 no-repeat;
            }
          }
        }
        @source.emojis.size.times do |index|
          rules << css_sprite_mapping(index)
        end
      end
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

    def css_sprite_mapping index
      offset = @sprite.offset index
      "#e_#{index+1} { background-position:-#{offset}px 0; }"
    end

    def sprite_path
      @sprite_path ||= File.join Emoji.tmp_dir, 'sprite.png'
    end

    def retina_sprite_path
      @retina_sprite_path ||= File.join Emoji.tmp_dir, 'sprite@2x.png'
    end

    def digest_name
      @digest_name ||= "sprite_%s.png" % Digest::MD5.hexdigest( File.read(sprite_path) )
    end

    def retina_digest_name
      @retina_digest_name ||= "sprite_%s@2x.png" % Digest::MD5.hexdigest( File.read(retina_sprite_path) )
    end

  end

  class Source

    def initialize file
      @file = file
    end

    def emojis
      @emojis ||= doc.css('#content img').find_all { |img| img['src'] =~ /emojis/ }
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

    private

    def doc
      @doc ||= Nokogiri::HTML File.open(@file)
    end

  end

  class Sprite

    def initialize files, size, padding
      @files   = files
      @size    = size
      @padding = padding
    end

    def offset index
      ((@size + @padding * 2) * index) + @padding
    end

    def generate path
      args = {
              tile: 'x1',
          geometry: "#{@size}x#{@size}+#{@padding}",
             depth: '8',
        background: 'transparent',
        sharpen: '0x1.5'
      }.map { |k, v| "-#{k} #{v}" }.join(' ')
      system "montage %s %s %s" % [ @files.join(' '), args, path ]
      optimize!(path)
    end

    private

    def optimize!(path)
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
