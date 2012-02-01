#!/usr/bin/env ruby

require "yaml"

log_file = File.expand_path("../update3322.log", __FILE__)

File.open(File.expand_path("../credentials.yml", __FILE__)) do |f|
  credentials = YAML.load(f.read)

  credential_3322 = credentials["3322.org"]
  user = credential_3322["user"]
  pass = credential_3322["password"]
  domain = credential_3322["domain"]

  cmd = %Q[lynx -mime_header -auth=#{user}:#{pass} "http://members.3322.net/dyndns/update?system=dyndns&hostname=#{domain}" 2>&1]
  output = `#{cmd}`
  result = $?.success?
  puts(result && "successfully update host ip\n#{output}" || "failed to update host ip.\n#{output}")

  #File.open(log_file, "a+") do |f|
  #  f.puts "-" * 80
  #  f.puts output
  #end
end

