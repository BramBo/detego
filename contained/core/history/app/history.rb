require 'yaml'
class History
  attr_reader :writer, :service, :domain, :thread
  def initialize(domain, service)
    @service = service
    @domain  = domain    
  end
  
  def prepare_write
    @writer = File.new("#{$service[:path]}/histories/#{@domain}::#{@service}.history", "a+")
  end
  
  def self.grab(domain, service)
    @histories ||= {}
    
    return (@histories["#{domain}::#{service}"].nil?) \
            ? @histories["#{domain}::#{service}"] = History.new(domain, service) \
            : @histories["#{domain}::#{service}"]
  end
  
  def self.write(domain, service, &block)
    history = History.grab(domain, service)
    history.prepare_write

    yield history.writer
    history.writer.puts ""
    history.writer.close
  end
end