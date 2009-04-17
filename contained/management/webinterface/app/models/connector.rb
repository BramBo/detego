require 'yaml'

class Connector
  attr_reader :domains
  
  def self.domains
    domains = []
    $provider.get_domains().each do |n|
      domains << Domain.new(n)
    end
    
    return domains
  end
  
  # find a domain or service matching te search query
  def self.locate(query)
    # add some search matching:
    query.gsub!(/[\s]+/   , ".+?")        # instead of (a) space(s) we insert a wildcard    
    query.gsub!(/[\_\-]/  , "[\_\s\-]*")  # '_' '=' or ' ' it doesn't mather
    query.gsub!(/[\:]+/   , "[\:]+")      # : == :: || :: == : etc.
    
    results  = {}
    $provider.get_domains().each do |d|
      domain_name                 = (d.to_s).downcase
      results[d]             = {}     
      results[d][:matches]   = 0
      results[d][:services]  = []
      
      if domain_name =~ /^.*?#{query}.*?$/i
        results[d][:matches] += 1
      end

      $provider.for(d).get_services().each do |s|
        service_name          = (s.to_s).downcase
        full_name             = "#{domain_name}::#{service_name}"
        
        puts "#{service_name} #{service_name.class}"
        if service_name =~ /^.*?#{query}.*?$/i || full_name =~ /^.*?#{query}.*?$/i
          results[d][:services] << service_name
          results[d][:matches]  += 1          
        end
      end
    end
    
    # finaly clear the non matches
    results.reject!{|k, m| m[:matches] <= 0}
    return results
  end
end

# Abusing meta programmaing once more to create an Hash which responds to keys as methods
class Hash
  def method_missing(method, *args, &block)
    return values_at(method.to_sym)  if(keys.include?(method.to_sym))
    return values_at(method.to_s)    if(keys.include?(method.to_s))
    
    super
  end
end