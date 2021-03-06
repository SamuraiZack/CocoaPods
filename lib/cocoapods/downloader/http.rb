require 'open-uri'
require 'tempfile'
require 'zlib'
require 'yaml'

module Pod
  class Downloader
    class Http < Downloader
      class UnsupportedFileTypeError < StandardError; end

      executable :curl
      executable :unzip
      executable :tar

      attr_accessor :filename, :download_path
      def download
        @filename        = filename_with_type type
        @download_path   = target_path + @filename
        UI.section(' > Downloading from HTTP', '', 3) do
          download_file @download_path
          extract_with_type @download_path, type
        end
      end

      def type
        options[:type] || type_with_url(url)
      end

      private
      def type_with_url(url)
        if url =~ /.zip$/
          :zip
        elsif url =~ /.(tgz|tar\.gz)$/
          :tgz
        elsif url =~ /.tar$/
          :tar
        elsif url =~ /.(tbz|tar\.bz2)$/
          :tbz
        else
          nil
        end
      end

      def filename_with_type(type=:zip)
        case type
        when :zip
          "file.zip"
        when :tgz
          "file.tgz"
        when :tar
          "file.tar"
        when :tbz
          "file.tbz"
        else
          raise UnsupportedFileTypeError.new "Unsupported file type: #{type}"
        end
      end

      def download_file(full_filename)
        curl! "-L -o '#{full_filename}' '#{url}'"
      end

      def extract_with_type(full_filename, type=:zip)
        case type
        when :zip
          unzip! "'#{full_filename}' -d '#{target_path}'"
        when :tgz
          tar! "xfz '#{full_filename}' -C '#{target_path}'"
        when :tar
          tar! "xf '#{full_filename}' -C '#{target_path}'"
        when :tbz
          tar! "xfj '#{full_filename}' -C '#{target_path}'"
        else
          raise UnsupportedFileTypeError.new "Unsupported file type: #{type}"
        end

        # If the archive is a tarball and it only contained a folder, move its contents to the target (#727)
        if [:tgz, :tar, :tbz].include? type
          contents = target_path.children
          contents.delete(full_filename)
          entry = contents.first
          if contents.count == 1 && entry.directory?
            FileUtils.move(entry.children, target_path)
          end
        end
      end

    end
  end
end
