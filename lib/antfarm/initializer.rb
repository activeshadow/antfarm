module Antfarm
  class << self
    attr_accessor :config

    def env
      return nil if @config.nil?
      return @config.environment
    end
  end

  class Initializer
    attr_reader :configuration

    # Run the initializer, first making the configuration object available
    # to the user, then creating a new initializer object, then running the
    # given command.
    def self.run(command = :process, configuration = Configuration.new)
      yield configuration if block_given?
      initializer = new configuration
      initializer.send(command)
    end

    def initialize(configuration)
      @configuration = configuration
    end

    def process
      update_configuration
      Antfarm.config = @configuration

      initialize_database
      initialize_logger
      initialize_outputter
    end

    def init
      # Load the Antfarm requirements
      load_requirements

      # Just getting rid of pesky deprication warning...
      I18n.enforce_available_locales = true

      # Make sure an application directory exists for the current user
      Antfarm::Helpers.create_user_directory
    end

    #######
    private
    #######

    def load_requirements
      require 'active_record'
      require 'logger'
      require 'yaml'

      require 'antfarm/errors'
      require 'antfarm/helpers'
      require 'antfarm/ipaddr'
      require 'antfarm/models'
      require 'antfarm/oui_parser'
      require 'antfarm/plugin'
      require 'antfarm/version'
    end

    def update_configuration
      begin
        config = YAML.load(IO.read(Antfarm::Helpers.config_file))
      rescue Errno::ENOENT # no such file...
        config = Hash.new
      end

      # If they weren't set in the configuration object when yielded,
      # then set them to the defaults specified in the user's config file.
      # If they don't exist in the config file, set them to the defaults
      # specified in the configuration object.
      if @configuration.environment.nil?
        if config['environment']
          @configuration.environment = config['environment']
        else
          @configuration.default_environment
        end
      end

      if @configuration.log_level.nil?
        if config['log_level']
          @configuration.log_level = config['log_level']
        else
          @configuration.default_log_level
        end
      end

      if @configuration.prefix.nil?
        if config['prefix']
          @configuration.prefix = config['prefix'].to_i
        else
          @configuration.default_prefix
        end
      end
    end

    # Currently, only PostgreSQL is supported.  The name of the ANTFARM
    # environment (which defaults to 'antfarm') is the name used for the
    # database and the log files.
    def initialize_database
      begin
        config = YAML.load(IO.read(Antfarm::Helpers.config_file))
      rescue Errno::ENOENT # no such file...
        config = Hash.new
      end

      # Database setup based on adapter specified
      # TODO: support passing of URL for DB connection as well
      if config && config[@configuration.environment] and config[@configuration.environment].has_key?('adapter')
        if config[@configuration.environment]['adapter']  == 'postgresql'
          config[@configuration.environment]['database'] ||= @configuration.environment
        else
          # If adapter specified isn't one of sqlite3 or postgresql, default to
          # PostgreSQL database configuration.
          config = nil
        end
      else
        # If the current environment configuration doesn't specify a database
        # adapter, default to PostgreSQL database configuration.
        config = nil
      end

      # Default to PostgreSQL database configuration
      config ||= { @configuration.environment => { 'adapter' => 'postgresql', 'database' => @configuration.environment } }

      ActiveRecord::Base.establish_connection(config[@configuration.environment])
    end

    def initialize_logger
      db_logger       = ::Logger.new(Antfarm::Helpers.db_log_file)
      db_logger.level = ::Logger.const_get(@configuration.log_level.upcase)
      ActiveRecord::Base.logger = db_logger

      logger       = ::Logger.new(Antfarm::Helpers.log_file)
      logger.level = ::Logger.const_get(@configuration.log_level.upcase)
      Antfarm.logger_callback = lambda do |severity,msg|
        logger.send(severity,msg.join)
      end
    end

    def initialize_outputter
      Antfarm.outputter_callback = @configuration.outputter
    end
  end

  class Configuration
    attr_accessor :environment
    attr_accessor :log_level
    attr_accessor :outputter
    attr_accessor :prefix

    def initialize
      @environment      = nil
      @log_level        = nil
      @outputter        = nil
      @prefix           = nil
    end

    def default_environment
      @environment = 'antfarm'
    end

    def default_log_level
      @log_level = 'warn'
    end

    def default_prefix
      @prefix = 30
    end
  end
end
