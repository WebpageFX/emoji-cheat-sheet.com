module SimpleS3Deploy
  module Asset
    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def filename
      File.basename path
    end

    def extension
      File.extname filename
    end

    def mime_type
      MIME::Types.type_for(path)[0].to_s
    end

  end
end
