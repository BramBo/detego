include_class('org.jruby.Ruby') {|pkg, name| "JJRuby" }

# @todo: fork to make processes asynch. Servers cant run synch. 
#         Probably best to do this using fork and drb to get the return value
class JJRuby
  def runScriptlet(code)  
      result = eval_scriptlet(%{
          begin
            #{code}
          rescue => e
            "Execution error: " + e.message
          end
        })
      if result.class.to_s.downcase =~ /string/ && !result.to_s.gsub!(/^execution.+?error\:/i, "").nil?
        ContainerLogger.error "#{result}", 2
        raise Exception.new("#{@full_name} #{result}")
      end

      return result
  end
end