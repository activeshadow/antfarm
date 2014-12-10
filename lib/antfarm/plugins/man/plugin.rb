module Antfarm
  module Man
    def self.registered(plugin)
      plugin.name = 'man'
      plugin.info = {
        desc:   'Show man page for ANTFARM or specified plugin',
        author: 'Bryan T. Richardson'
      }
    end

    def run(opts = Hash.new)
      groff = 'groff -Wall -mtty-char -mandoc -Tascii'
      pager = ENV['MANPAGER'] || ENV['PAGER'] || 'more'
      pid   = nil

      if ARGV.empty?
        path = Antfarm.root + '/man/antfarm.1'
      else
        if plugin = Antfarm.plugins[ARGV.shift]
          path = plugin.manpage_path
        end
      end

      if path
        rd, wr = IO.pipe
        if pid = fork
          rd.close
        else
          wr.close
          STDIN.reopen rd
          exec "#{groff} | #{pager}"
        end

        wr.puts(File.read(path))

        if pid
          wr.close
          Process.wait
        end
      else
        if plugin
          Antfarm.output 'The man page you requested does not exist'
        else
          Antfarm.output "The plugin you requested a man page for is unknown.\n"
          Antfarm.output "Below is a list of known plugins.\n\n"

          # TODO: write helper method for listing plugins
          Antfarm.plugins.each do |k,v|
            Antfarm.output "#{k} - #{v.info[:desc]}"
          end
        end
      end
    end
  end
end

Antfarm.register(Antfarm::Man)
