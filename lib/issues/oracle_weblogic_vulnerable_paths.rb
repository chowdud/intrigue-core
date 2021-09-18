module Intrigue
module Issue
class OracleWeblogicVulnerablePaths < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "oracle_weblogic_vulnerable_paths",
      pretty_name: "Oracle Weblogic Vulnerable Paths",
      severity: 2,
      category: "vulnerability",
      status: "confirmed",
      description: "This server is exposing paths known to be susceptible to many vulnerabilities.",
      remediation: "Block access to these paths.",
      affected_software: [
        { :vendor => "Oracle", :product => "Weblogic Server" }
      ],
      references: [
        { type: "description", uri: "https://docs.oracle.com/middleware/1212/wls/INTRO/security.htm#INTRO246" }
      ],
      task: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end