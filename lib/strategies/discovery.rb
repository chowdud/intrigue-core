module Intrigue
module Strategy
  class Discovery < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "discovery",
        :pretty_name => "Discovery",
        :authors => ["jcran"],
        :description => "This strategy performs a light recursive discovery."
      }
    end

    def self.recurse(entity, task_result)

      if entity.type_string == "FtpServer"

        start_recursive_task(task_result,"ftp_banner_grab",entity,[])

      elsif entity.type_string == "DnsRecord"

        ### DNS Subdomain Bruteforce
        # Do a big bruteforce if the size is small enough
        if (entity.name.split(".").length < 3)
          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => true }])

        else
          # otherwise do something a little faster
          start_recursive_task(task_result,"dns_brute_sub",entity,[])
        end

      elsif entity.type_string == "IpAddress"

        # Prevent us from hammering on whois services
        unless ( entity.created_by?("net_block_expand")||
                 entity.created_by?("masscan_scan") ||
                 entity.created_by?("nmap_scan") )
          start_recursive_task(task_result,"whois",entity)
        end

      elsif entity.type_string == "String"

        # Search, only snag the top result
        start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

      elsif entity.type_string == "NetBlock"

        # Make sure it's small enough not to be disruptive, and if it is, scan it
        if entity.details["whois_full_text"] =~ /#{task_result.scan_result.base_entity.name}/
          #start_recursive_task(task_result,"net_block_expand",entity, [])
          start_recursive_task(task_result,"nmap_scan",entity)
        else
          task_result.log "Cowardly refusing to expand this netblock."
        end


      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity) if entity.name =~ /^https/

        ## Spider, looking for metadata
        start_recursive_task(task_result,"uri_spider",entity,[
            {"name" => "threads", "value" => 1},
            {"name" => "max_pages", "value" => 100 },
            {"name" => "parse_file_metadata", "value" => false},
            {"name" => "extract_dns_records", "value" => true},
            {"name" => "extract_dns_record_pattern", "value" => "#{task_result.scan_result.base_entity.name}"}]) unless entity.created_by? "uri_brute"

        # Check for exploitable URIs, but don't recurse on things we've already found
        start_recursive_task(task_result,"uri_brute", entity, [
          {"name"=> "threads", "value" => 1},
          {"name" => "user_list", "value" => "admin, test, server-status, .svn, .git, wp-config.php, config.php, configuration.php, LocalSettings.php, mediawiki/LocalSettings.php, mt-config.cgi, mt-static/mt-config.cgi, settings.php, .htaccess, config.bak, config.php.bak, config.php~, #config.php#, config.php.save, .config.php.swp, config.php.swp, config.php.old"}]) unless entity.created_by? "uri_brute"

      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
