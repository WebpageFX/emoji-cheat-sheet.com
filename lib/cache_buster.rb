require_relative 'cache_busted_file'

module SimpleS3Deploy
  class CacheBuster
    attr_reader :file

    def initialize path
      @file = CacheBustedFile.new path
    end

    def self.run path, &block
      buster = self.new path

      buster.run

      yield

    ensure
      buster.cleanup
    end

    def run
      # Append the digest value of each image to their filename
      # and update their references in the stylesheets
      images.each do |img|
        img.rename_to_digested_filename
        stylesheets.each do |stylesheet|
          stylesheet.data.gsub! "\/#{img.original_filename}", "\/#{img.digested_filename}"
        end
      end

      # Persist the stylesheets, append their digest values to the filenames
      # and update the references to them in the html file
      stylesheets.each do |stylesheet|
        stylesheet.write
        stylesheet.rename_to_digested_filename

        file.data.gsub! stylesheet.original_filename, stylesheet.digested_filename
      end

      file.write
    end

    # Reverts all changes done by the run method
    def cleanup
      images.each do |img|
        img.rename_to_original_filename
      end

      stylesheets.each do |stylesheet|
        stylesheet.data = stylesheet.original_data
        stylesheet.write
        stylesheet.rename_to_original_filename

        file.data.gsub! stylesheet.digested_filename, stylesheet.original_filename
      end

      file.write
    end

    def stylesheets
      @stylesheets ||= find_stylesheets
    end

    def find_stylesheets doc = self.doc
      doc.css('link[rel="stylesheet"]').reject do |link|
        link['href'].start_with? 'http'
      end.map do |link|
        CacheBustedFile.new File.expand_path(File.join(file.path, '../', link['href']))
      end
    end

    def images
      @images ||= find_images
    end

    def find_images
      images = []
      stylesheets.each do |stylesheet|
        matches = stylesheet.data.scan /url\((.*)\)/
        paths = matches.flatten.map { |match| match.gsub(/"|'/, '')}
        images += paths.map do |p|
          CacheBustedFile.new File.expand_path(File.join(stylesheet.path, '../', p))
        end
      end

      images
    end

    def doc
      Nokogiri::HTML File.read file.path
    end

  end
end
