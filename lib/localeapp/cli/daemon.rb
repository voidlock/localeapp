module Localeapp
  module CLI
    class Daemon < Update
      def execute(options)
        interval = options[:interval].to_i

        if interval <= 0
          exit_now! "interval must be a positive integer greater than 0", 1
        end

        startup(options[:background])
        update_loop(interval)
      end

      def update_loop(interval)
        until @shutdown
          do_update
          sleep interval
        end
      end

      def startup(background)
        if background
          daemonize
          write_pid_file
          STDOUT.reopen(File.open(Localeapp.configuration.daemon_log_file, 'a'))
        end
        enable_gc_optimizations
        register_signal_handlers
        STDOUT.sync = true
      end

      def pid
        @pid ||= Process.pid
      end

      def kill_existing
        if File.exists? Localeapp.configuration.daemon_pid_file
          begin
            daemon_pid = File.read(Localeapp.configuration.daemon_pid_file)
            Process.kill("QUIT", daemon_pid.to_i)
          rescue Errno::ESRCH
            File.delete(Localeapp.configuration.daemon_pid_file)
          end
        end
      end

      def daemonize
        kill_existing
        if Process.respond_to?(:daemon)
          Process.daemon(true, true)
        else
          Kernel.warn "Running process as daemon requires ruby >= 1.9"
        end
      end

      def write_pid_file
        File.open(Localeapp.configuration.daemon_pid_file, 'w') {|f| f << self.pid}
      end

      def enable_gc_optimizations
        if GC.respond_to?(:copy_on_write_friendly=)
          GC.copy_on_write_friendly = true
        end
      end

      def register_signal_handlers
        trap('QUIT') { shutdown! }
        trap('TERM') { shutdown! }
        trap('INT') { shutdown! }
        trap('HUP', 'IGNORE')
      end

      def unregister_signal_handlers
        trap('QUIT', 'DEFAULT')
        trap('TERM', 'DEFAULT')
        trap('INT', 'DEFAULT')
        trap('HUP', 'IGNORE')
      end

      def shutdown!
        STDOUT.flush
        @shutdown = true
      end
    end
  end
end
