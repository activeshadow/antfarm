require 'pry'
include Antfarm::Models

module Antfarm
  module Console
    def self.registered(plugin)
      plugin.name = 'console'
      plugin.info = {
        desc:   'Drop into a Pry console with access to data models',
        author: 'Bryan T. Richardson'
      }
    end

    def run(opts = Hash.new)
      Pry.config.prompt_name  = 'console'
      Pry.config.history.file = Antfarm::Helpers.history_file

      # TODO: what was I up to here?
      Antfarm.plugins.each do |name,plugin|
        Pry::Commands.block_command name, plugin.info[:desc] do |opts|
        end
      end

      Antfarm.pry
    end
  end
end

Antfarm.register(Antfarm::Console)
