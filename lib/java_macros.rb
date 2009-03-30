include_class('org.jruby.Ruby') {|pkg, name| "JJRuby" }


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
        ContainerLogger.debug "#{result}" 
        raise Exception.new("#{@full_name} #{result}")
      end
      
      return result
  end
end