#!/usr/bin/env ruby

# Sample 'sensors' output
# coretemp-isa-0000
# Adapter: ISA adapter
# Physical id 0:  +29.0°C  (high = +85.0°C, crit = +105.0°C)
# Core 0:         +23.0°C  (high = +85.0°C, crit = +105.0°C)
# Core 1:         +17.0°C  (high = +85.0°C, crit = +105.0°C)
# Core 2:         +26.0°C  (high = +85.0°C, crit = +105.0°C)
# Core 3:         +29.0°C  (high = +85.0°C, crit = +105.0°C)

header_displayed = false
while true
  sensors = `sensors`

  temps = []
  sensors.each do |l|
    next unless /Core .:\s*\+([0-9.]*)°C/ =~ l

    temps << $1.to_f
  end

  if !header_displayed
    header = 1.upto(temps.size).map {|i| "Core #{i}"}.join("\t\t")
    puts header

    header_displayed = true
  end

  print "\r"

  display = temps.map {|t| "%2.1f°C" % t}.join("\t\t")
  print display
  $stdout.flush

  sleep(.5)
end
