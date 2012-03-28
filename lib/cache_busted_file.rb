require_relative 'asset'

module SimpleS3Deploy
  class CacheBustedFile
    include Asset

    attr_reader :original_filename,
                :original_path,
                :original_data
    attr_writer :path

    def initialize path
      @original_path = path
      @original_filename = filename
    end

    def path
      @path ||= @original_path
    end

    def rename_to_digested_filename
      self.path = File.join(File.dirname(path), digested_filename)
      FileUtils.mv @original_path, path
    end

    def rename_to_original_filename
      self.path = @original_path
      FileUtils.mv File.join(File.dirname(path), digested_filename), path
    end

    def digest
      @digest ||= Digest::MD5.hexdigest data
    end

    def digested_filename
      @original_filename.gsub '.', "_#{digest}."
    end

    def data= content, should_persist = true
      unless content == self.data
        @data = content
        write if should_persist
      end

      @data
    end

    def data
      @original_data ||= read
      @data ||= @original_data
    end

    def write
      File.open(path, 'w') { |f| f.write @data }
    end

    def read
      File.read path
    end

  end
end
