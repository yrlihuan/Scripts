#!/usr/bin/env ruby

require "rubygems"
require "optparse"

def block_ssh_access
  puts "block access to port 22"
  cmd = "sudo iptables -A INPUT -p tcp --dport 22 -j DROP"
  `#{cmd}`
end

def add_home_computer_to_white_list
  hosts = ["hit.3322.org", "hthunder.tk"]

  hosts.each do |h|
    homeip = `host #{h} | awk '{print $4}'`[0...-1]

    # skip if it's not an ip
    puts "not a valid ip: #{homeip}" if homeip.split('.').count != 4
    next if homeip.split('.').count != 4

    search = `sudo iptables -nvL | grep ACCEPT.*#{homeip}.*tcp.*22`
    if search.length > 0
      puts "ip #{homeip} already granted access to port 22"
      next
    end

    puts "grant #{homeip} access to port 22"
    cmd = "sudo iptables -A INPUT -p tcp -s #{homeip} --dport 22 -j ACCEPT"
    `#{cmd}`
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}
  opts = OptionParser.new do |opts|
    opts.on("-b", "--block", "blockl access on port 22") do |b|
      options[:block] = true
    end

    opts.on("-w", "--whitelist", "add specific machine to whitelist") do |w|
      options[:block] = false
    end
  end

  opts.parse!

  if options[:block]
    block_ssh_access
  else
    add_home_computer_to_white_list
  end
end
