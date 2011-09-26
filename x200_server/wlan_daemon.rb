#! /usr/bin/env ruby

def test_connect_ap
  ap_addr = "192.168.1.1"
  cmd = "ping -c 4 #{ap_addr}"
  `#{cmd}`
  $?.success?
end

def restart_interface
  wlan_interface = "wlan1"

  `ifconfig #{wlan_interface} down`

  sleep 10
  `ifconfig #{wlan_interface} up`
end

def main
  while true
    unless test_connect_ap
      restart_interface
    end

    sleep 600
  end
end

if $PROGRAM_NAME == __FILE__
  main
end

