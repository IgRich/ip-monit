namespace :db do
  require 'sequel'

  desc 'Create database'
  task :create do
    DbConnection.admin_connect do |conn|
      db_name = DbConnection.config['db']['database']
      database_exists = conn["SELECT * FROM pg_database WHERE datname='#{db_name}'"].count > 0
      if database_exists
        puts "Database '#{db_name}' already exists!"
      else
        conn.run "CREATE DATABASE #{db_name}"
        puts "Database '#{db_name}' created"
      end
    end
  end

  desc 'Drop database'
  task :drop do
    DbConnection.admin_connect do |conn|
      db_name = DbConnection.config['db']['database']
      conn.run "DROP DATABASE #{db_name}"

      puts "Database '#{db_name}' dropped"
    end
  end

  desc 'Create migration file'
  task :create_migration, [:name] do |_, args|
    argv = args[:name] || (raise ArgumentError.new("Migration name is not present"))

    migration = <<~FILE
      Sequel.migration do
        up do
        end

        down do
        end
      end
    FILE

    migration_name = [DateTime.now.strftime('%Y%m%d%H%M%S'), argv].join('_')

    File.write("#{Dir.getwd}/migrations/#{migration_name}.rb", migration)

    puts "Migration '#{migration_name}' created"
  end

  desc 'Perform migration up to latest migration available'
  task :migrate do
    Sequel.extension(:migration)
    Sequel::Migrator.run(DbConnection.connect, "migrations", table: 'sequel_migrations')
    Rake::Task['db:version'].execute
  end

  desc 'Perform migration down to one step'
  task :rollback do
    Sequel.extension(:migration)
    Sequel::Migrator.run(DbConnection.connect, "migrations", table: 'sequel_migrations', target: versions[-2].to_i)
    Rake::Task['db:version'].execute
  end

  desc 'Prints current schema version'
  task :version do
    puts "Schema version: #{versions.last}"
  end

  def versions
    DbConnection.connect[:sequel_migrations].map{ |i| i[:filename].split('_')[0].to_i }.sort
  end
end
