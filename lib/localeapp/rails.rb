require 'fileutils'

module Localeapp
  module Rails
    def self.initialize
      if defined?(::Rails.logger)
        rails_logger = ::Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        rails_logger = RAILS_DEFAULT_LOGGER
      end

      if defined?(::Rails.env)
        rails_env = ::Rails.env
      elsif defined?(RAILS_ENV)
        rails_env = RAILS_ENV
      end

      if defined?(::Rails.root)
        rails_root = ::Rails.root
      elsif defined?(RAILS_ROOT)
        rails_root = RAILS_ROOT
      end

      ActionController::Base.send(:include, Localeapp::Rails::Controller)

      if ::Rails::VERSION::MAJOR == 2 && ::Rails::VERSION::MINOR >= 3 # TODO: Check previous rails versions if required
        require 'localeapp/rails/2_3_translation_helper_monkeypatch'
      end

      Localeapp.configure do |config|
        config.logger                     = rails_logger
        config.environment_name           = rails_env
        config.project_root               = rails_root
        config.synchronization_data_file  = File.join([rails_root, 'log', 'localeapp.yml'])
        config.translation_data_directory = File.join([rails_root, 'config', 'locales'])
      end
      initialize_synchronization_data_file
    end

    def self.initialize_synchronization_data_file
      sync_file = Localeapp.configuration.synchronization_data_file
      if !File.exists?(sync_file)
        FileUtils.mkdir_p(File.dirname(sync_file))
        File.open(sync_file, 'w') do |f|
          f.write({:polled_at => Time.now.to_i, :updated_at => Time.now.to_i}.to_yaml)
        end
      end
    end
  end
end

if defined?(Rails)
  require 'localeapp/rails/controller'
  require 'localeapp/exception_handler'
  Localeapp::Rails.initialize
  Localeapp.log('Loaded localeapp/rails')
end
