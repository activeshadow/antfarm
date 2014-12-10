require 'fileutils'

module Antfarm
  module Init
    def self.registered(plugin)
      plugin.name = 'init'
      plugin.info = {
        desc:   'Initialize the database, log files, etc.',
        author: 'Bryan T. Richardson'
      }
      plugin.options = [{
        name: 'all',
        desc: 'Initialize all the database tables, including ones for plugins'
      },
      {
        name: 'plugin',
        desc: 'Include schema only the specified plugin',
        type: String
      }]
    end

    def run(opts = Hash.new)
      check_options(opts)

      Antfarm.output "Updating database for #{Antfarm.env} environment!\n\n"

      FileUtils.rm_f(Antfarm::Helpers.db_file)
      FileUtils.rm_f(Antfarm::Helpers.log_file)

      load 'antfarm/schema.rb'

      if opts[:all]
        Dir["#{Antfarm.root}/lib/antfarm/plugins/*/**/schema.rb"].each  { |file| load file }
        Dir["#{Antfarm::Helpers.user_plugins_dir}/*/**/schema.rb"].each { |file| load file }
      elsif plugin = opts[:plugin]
        Dir["#{Antfarm.root}/lib/antfarm/plugins/#{plugin}/schema.rb"].each  { |file| load file }
        Dir["#{Antfarm::Helpers.user_plugins_dir}/#{plugin}/schema.rb"].each { |file| load file }
      end
    end
  end
end

Antfarm.register(Antfarm::Init)
