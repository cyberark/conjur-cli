require 'gli'
require 'conjur/config'

module Conjur
  class CLI
    extend GLI::App

    class << self
      def load_config
        [ File.join("/etc", "conjur.conf"), ( ENV['CONJURRC'] || File.join(ENV['HOME'], ".conjurrc") ) ].each do |f|
          if File.exists?(f)
            $stderr.puts "Loading #{f}"
            Conjur::Config.merge YAML.load(IO.read(f))
          end
        end
      end
    end
            
    load_config
            
    ENV['CONJUR_ENV'] = Config[:env] if Config[:env]
    ENV['CONJUR_STACK'] = Config[:stack] if Config[:stack]
    
    Conjur::Config.plugins.each do |plugin|
      require "conjur-asset-#{plugin}"
    end
    
    commands_from 'conjur/command'

    $stderr.puts "Using host #{Conjur::Authn::API.host}"
    
    pre do |global,command,options,args|
      require 'active_support/core_ext'
      options.delete_if{|k,v| v.blank?}
      options.symbolize_keys!
      
      if as_group = options.delete(:"as-group")
        group = Conjur::Command.api.group(as_group)
        role = Conjur::Command.api.role(group.roleid)
        exit_now!("Group '#{as_group}' doesn't exist, or you don't have permission to use it") unless role.exists?
        options[:"ownerid"] = group.roleid
      end
      if as_role = options.delete(:"as-role")
        role = Conjur::Command.api.role(as_role)
        exit_now!("Role '#{as_role}' does not exist, or you don't have permission to use it") unless role.exists?
        options[:"ownerid"] = role.id
      end
      
      true
    end
    
    on_error do |exception|
      if exception.is_a?(GLI::StandardException)
        # pass
      elsif exception.is_a?(RestClient::Exception)
        begin
          body = JSON.parse(exception.response.body)
          $stderr.puts body['error']
        rescue
          $stderr.puts exception.response.body if exception.response
        end
      end
      true
    end
  end
end