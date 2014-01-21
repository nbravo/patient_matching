module Chla
  class PatientMatchProcessor < LomiLomi::Processor

    def initialize(options = {}, &blk)
      super(&blk)
      
    end

    def do_process(obj)
      # TODO: process object here...
      obj
    end

  end
end
