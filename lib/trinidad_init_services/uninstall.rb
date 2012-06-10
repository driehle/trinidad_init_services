module Trinidad
  module InitServices
    class Uninstall
      def initialize(stdin = STDIN, stdout = STDOUT)
        @stdin = stdin
        @stdout = stdout
      end

      # uninstall a Trinidad service
      def uninstall(config = {})
        if windows?
          @service_name = config["service_name"] || ask("Service name", "Trinidad")
          uninstall_windows_service
        elsif macosx?
          @service_name = config["service_name"] || ask("Service name", "Trinidad")
          @output_path = config["output_path"]   || ask("Output path", "/etc/init.d")
          uninstall_unix_service
        else
          puts "Unknown operating system."
        end
      end

      private
      # uninstallation procedure for Windows systems
      def uninstall_windows_service
        srv_path = detect_prunsrv_path
        trinidad_service_id = @service_name.gsub(/\W/, '')
        command = "//DS//#{trinidad_service_id}"
        system "#{srv_path} #{command}"
      end

      # uninstallation procedure for Unix systems
      def uninstall_unix_service
        # Maybe in the future support a "service name" for Unix systems like this
        #trinidad_file = File.join(@output_path, "trinidad-" + @service_name.gsub(/\W/, '').downcase)
        trinidad_file = File.join(@output_path, "trinidad")
        puts "Deleting #{trinidad_file} ..."
        File.delete(trinidad_file)
      end

      def windows?
        RbConfig::CONFIG['host_os'] =~ /mswin|mingw/i
      end

      def macosx?
        RbConfig::CONFIG['host_os'] =~ /darwin/i
      end

      def detect_prunsrv_path # only called on windows
        prunsrv_path = `for %i in (prunsrv.exe) do @echo.%~$PATH:i` rescue ''
        # a kind of `which prunsrv.exe` (if not found returns "\n")
        prunsrv_path.chomp!
        prunsrv_path.empty? ? bundled_prunsrv_path : prunsrv_path
      end

      def bundled_prunsrv_path(arch = java.lang.System.getProperty("os.arch"))
        # "amd64", "i386", "x86", "x86_64"
        path = 'windows'
        if arch =~ /amd64/i # amd64
          path += '/amd64'
        elsif arch =~ /64/i # x86_64
          path += '/ia64'
                            # else "i386", "x86"
        end
        File.join(File.expand_path('../../../trinidad-libs', __FILE__), path, 'prunsrv.exe')
      end

      def ask_path(question, default = nil)
        path = ask(question, default)
        path.empty? ? path : File.expand_path(path)
      end

      def ask(question, default = nil)
        return nil if not @stdin.tty?

        question << " [#{default}]" if default && !default.empty?

        result = nil

        while result.nil?
          @stdout.print(question + "  ")
          @stdout.flush

          result = @stdin.gets

          if result
            result.chomp!

            result = case result
                       when /^$/
                         default
                       else
                         result
                     end
          end
        end
        return result
      end
    end
  end
end

