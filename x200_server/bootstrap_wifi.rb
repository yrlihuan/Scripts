#! /usr/bin/env ruby

# wait for system initialization to finish
sleep 20

while true
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

  lines = wlan_list.split("\n")
  ind = 0
  while ind + 2 < lines.length
    # First line is like "0: phy0: Wireless LAN"
    adapter_id = lines[ind].split(":")[0].to_i

    # Second line is like "\tSoft blocked: no"
    soft_blocked = lines[ind+1].end_with? "yes"

    # Third line is like "\tHard blocked: no"
    hard_blocked = lines[ind+2].end_with? "yes"

    if true
      cmd = "rfkill unblock all"
      `#{cmd}`
    end

    ind += 3
  end

  sleep 60
end
