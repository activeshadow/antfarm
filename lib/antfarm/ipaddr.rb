require 'ipaddr'

class IPAddr
  attr_accessor :netmask

  class << self
    alias_method  :__new__, :new

    def new(addr = '::', family = Socket::AF_UNSPEC, build_netmask = true)
      address, netmask = addr.split('/')
      ipaddr = __new__(addr, family)

      if build_netmask
        if ipaddr.ipv4?
          net       = IPAddr.new('255.255.255.255', Socket::AF_UNSPEC, false)
          netmask ||= 32
        elsif ipaddr.ipv6?
          net       = IPAddr.new('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', Socket::AF_UNSPEC, false)
          netmask ||= 128
        end

        ipaddr.netmask = net.mask(netmask)
      end

      return ipaddr
    end
  end

  def network
    return self.mask(@netmask.to_s)
  end

  def cidr
    addr_bits = case
                when self.ipv4? then 32
                when self.ipv6? then 128
                else
                  32
                end

    unless (~@netmask).to_i == 0
      res = Math.log((~@netmask).to_i) / Math.log(2)
      if res.finite?
        addr_bits -= res.round
      end
    end

    return addr_bits
  end

  def to_cidr_string
    str = sprintf("%s/%i", self.network.to_string, self.cidr)
  end

  def broadcast
    return self.network | ~@netmask
  end

  def loopback?
    [
      IPAddr.new('127.0.0.0/8'), IPAddr.new('::1'), IPAddr.new('fe00::/10')
    ].each { |net| return true if net.include?(self) }

    return false
  end

  def private?
    [
      IPAddr.new('10.0.0.0/8'),     IPAddr.new('172.16.0.0/12'),
      IPAddr.new('192.168.0.0/16'), IPAddr.new('fe80::/10'),
      IPAddr.new('fec0::/10')
    ].each { |net| return true if net.include?(self) }

    return false
  end

  def multicast?
    [
      IPAddr.new('224.0.0.0/4'), IPAddr.new('ff00::/8')
    ].each { |net| return true if net.include?(self) }

    return false
  end

  alias_method :__include__, :include?

  def include?(other)
    return false unless self.__include__(other.network)
    return false unless self.__include__(other.broadcast)
    return true
  end
end
