module Share
  class Controller
    def initialize(options={})
      @options = {}
      @documents = {}
      @awaiting_get = {}

      @options.reap_time ||= 30.seconds
      @options.num_cached_ops ||= 10      
      @options.force_reaping ||= false
      @options.ops_before_commit ||= 20
      @options.maximum_age ||= 40
    end
  end
end