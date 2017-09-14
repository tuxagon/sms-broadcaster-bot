require 'sequel'
require 'yaml'

namespace :db do

  desc 'Run migrations'
  task :migrate, [:version] do |t, args|
    Sequel.extension :migration
    connection_details = YAML.load(File.open('config/database.yml'))
    db = Sequel.connect(connection_details)
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, 'db/migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(db, 'db/migrations')
    end
  end

end
