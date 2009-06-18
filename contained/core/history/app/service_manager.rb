class ServiceManager
  def initialize
    $provider.subscribe($provider.const_get(:DOMAIN) , :all)    
    $provider.subscribe($provider.const_get(:SERVICE), :all)
  end
  
  def start
    self.status = "Started !"
  end
  
  def update(group, event, params)  
    History.write(params[:domain], params[:service]) do |writer|
      writer.puts Time.now.to_s.console_bold 
      writer.puts "Event-group: #{group}".console_dark_yellow
      writer.puts "Event-descr: #{event} ".console_dark_yellow
      writer.puts "Params: #{params.to_yaml.to_s.console_blue}".console_dark_yellow
    end
  end
end