module Antfarm
  class AntfarmError < RuntimeError
    def initialize(message)
      super

      message = "#{self.class}: #{message}"
      Antfarm.output("Exception: #{message}")
      Antfarm.log :error, message
    end
  end
end
