module Localeapp
  module Rails
    module Controller
      def self.included(base)
        base.before_filter :handle_translation_updates
        base.after_filter  :send_missing_translations
      end

      def handle_translation_updates
        unless ::Localeapp.configuration.polling_disabled?
          ::Localeapp.log_with_time 'Handling translation updates'
          if ::Localeapp.poller.needs_polling?
            ::Localeapp.log_with_time 'polling'
            ::Localeapp.poller.poll!
          end
        end

        unless ::Localeapp.configuration.reloading_disabled?
          if ::Localeapp.poller.needs_reloading?
            ::Localeapp.log_with_time 'reloading I18n'
            I18n.reload!
            ::Localeapp.poller.read_synchronization_data!
          end
        end
      end

      def send_missing_translations
        return if ::Localeapp.configuration.sending_disabled?

        ::Localeapp.sender.post_missing_translations
      end
    end
  end
end
