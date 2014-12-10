require 'ipaddr'

class IPAddr
  def prefix
    return @mask_addr.to_s(2).count('1')
  end

  def prefix=(prefix)
    self.mask!(prefix)
  end

  def to_cidr_string
    str = sprintf("%s/%i", self.to_s, self.prefix)
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
end
