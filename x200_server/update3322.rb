#!/usr/bin/env ruby

require "yaml"

File.open("credentials.yml") do |f|
  credentials = YAML.load(f.read)

  credential_3322 = credentials["3322.org"]
  user = credential_3322["user"]
  pass = credential_3322["password"]
  domain = credential_3322["domain"]

  cmd = %Q[lynx -mime_header -auth=#{user}:#{pass} "http://members.3322.net/dyndns/update?system=dyndns&hostname=#{domain}"]
  output = `#{cmd}`
  result = $?.success?
  puts(result && "successfully update host ip" || "failed to update host ip.\n#{output}")
end
