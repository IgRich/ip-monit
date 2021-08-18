class DbConnection
  class << self
    def connect
      @db ||= Sequel.connect(config['db'])
    end

    def disconnect
      @db.disconnect
    end

    def admin_connect
      Sequel.connect(config['db'].merge('database' => 'postgres')) { |conn| yield(conn) }
    end

    def config
      unless defined? @config
        config_string = ERB.new(File.read(File.expand_path("#{ENV['ROOT_DIR']}/config/database.yml"))).
          result(binding)
        @config ||= YAML.load(config_string)[ENV['RAKE_ENV']]
      end
      @config
    end
  end
end
