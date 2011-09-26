#! /usr/bin/env ruby

def test_connect_ap
  ap_addr = "192.168.1.1"
  cmd = "ping -c 4 #{ap_addr}"
  `#{cmd}`
  $?.success?
end


def log_interface_state
  iwconfig_result = `iwconfig`
  wlan_list = `rfkill list`

  File.open(File.expand_path("../bootstrap_wifi.log", __FILE__), "a+") do |f|
    f.puts("-" * 80)
    f.puts(Time.now)
    f.puts("iwconfig:")
    f.puts(iwconfig_result)
    f.puts("rfkill list:")
    f.puts(wlan_list)
  end
end

def bootstrap
  # wait for system initialization to finish
  sleep 60

  while true
    wlan_list = `rfkill list`
    lines = wlan_list.split("\n")
    ind = 0

    unless test_connect_ap
      log_interface_state
    end

    while ind + 2 < lines.length
      # First line is like "0: phy0: Wireless LAN"
      adapter_id = lines[ind].split(":")[0].to_i

      # Second line is like "\tSoft blocked: no"
      soft_blocked = lines[ind+1].end_with? "yes"

      # Third line is like "\tHard blocked: no"
      hard_blocked = lines[ind+2].end_with? "yes"

      if soft_blocked
        cmd = "rfkill unblock all"
        `#{cmd}`
      end

      ind += 3
    end

    sleep 600
  end
end

if $PROGRAM_NAME == __FILE__
  bootstrap
end

