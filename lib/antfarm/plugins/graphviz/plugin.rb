require 'graphviz'

module Antfarm
  module GraphViz
    def self.registered(plugin)
      plugin.name = 'graphviz'
      plugin.info = {
        desc:   'Visualize network data in DB using Graphviz',
        author: 'Bryan T. Richardson'
      }
      plugin.options = [{
        name:     'file_name',
        desc:     'Where to save output file to',
        type:     String,
        required: true
      },
      {
        name: 'tags',
        desc: 'Node tags, separated by commas, to include (otherwise, all nodes will be included)',
        type: String
      }]
    end

    def run(opts = Hash.new)
      check_options(opts)

      n = Hash.new
      g = ::GraphViz.new(:G, type: :digraph)
      g.node[:shape] = 'box'
      g.edge[:dir]   = 'none'

      Antfarm::Models::IPNet.all.each do |network|
        n[network.id] = g.add_nodes(network.address.to_cidr_string, color: 'red', shape: 'ellipse')
      end

      Antfarm::Models::IPIf.all.each do |iface|
        node    = g.add_nodes(iface.address.to_s, color: 'green', label: "#{iface.address.to_s}\n\nVLAN 100\nVLAN 200")
        network = iface.network

        g.add_edges(n[network.id], node, label: 'deny') if network
      end

      g.output(png: opts[:file_name])
    end
  end
end

Antfarm.register(Antfarm::GraphViz)
