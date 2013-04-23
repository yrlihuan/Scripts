#!/usr/bin/env ruby

require "rubygems"
require "optparse"

def block_ssh_access
  search = `sudo iptables -nvL | grep DROP.*tcp.*22`
  if search.length > 0
    puts "port 22 already restricted"
  else
    puts "block access to port 22"
    cmd = "sudo iptables -A INPUT -p tcp --dport 22 -j DROP"
    `#{cmd}`
  end
end

def add_home_computer_to_white_list
  hosts = ["hit.3322.org", "thunder.hvps.tk", "eagle.hvps.tk", "mustang.hvps.tk", "192.168.1.0/24"]

  hosts.each do |h|
    if h.start_with? '192'
      homeip = h
    else
      homeip = `host #{h} | awk '{print $4}'`[0...-1]
    end

    # skip if it's not an ip
    puts "not a valid ip: #{homeip}" if homeip.split('.').count != 4
    next if homeip.split('.').count != 4

    search = `sudo iptables -nvL | grep ACCEPT.*#{homeip}.*tcp.*22`
    if search.length > 0
      puts "ip #{homeip} already granted access to port 22"
      next
    end

    puts "grant #{homeip} access to port 22"
    cmd = "sudo iptables -I INPUT 1 -p tcp -s #{homeip} --dport 22 -j ACCEPT"
    `#{cmd}`
  end
end

if $PROGRAM_NAME == __FILE__
  block_ssh_access
  add_home_computer_to_white_list
end
