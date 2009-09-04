module ServiceCodeBase
  class Config < Hash 
    def method_missing(method_name, *args, &block)
      return (method_name.to_s =~ /\=$/) \
              ? self[:"#{method_name.to_s.sub(/\=$/, '')}"]= args \
              : self[:"#{method_name}"]
    end
  end
    
  class Initializer  
    def self.configure(&block)
      yield(self.config) if block_given?
    end
  
    def self.config
      @config ||= Config.new
    end
  end
end