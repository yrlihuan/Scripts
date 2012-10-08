#!/usr/bin/env ruby

require "time"

def usage()
"""usage:
  site_stat.rb <pattern> <start> <end>

sample:
  site_stat.rb index.html 2012-10-08 2012-10-09
"""
end

if $PROGRAM_NAME == __FILE__
  if ARGV.length != 3
    puts usage()
    exit
  end

  pattern = ARGV[0]
  start_d = Time.parse ARGV[1]
  end_d = Time.parse ARGV[2]

  if start_d >= end_d
    puts "'end' must be a later date of 'start'"
    exit
  end

  files = `ls -rt` # sort by modified time. oldest first
  unless files.include? 'other_vhosts_access'
    puts "the script must be run under /var/log/apache2/"
    exit
  end

  logs = []
  files.split.each do |f|
    next unless f.include? 'other_vhosts_access'

    logs << f
  end

  # stats saved results
  # it's a dict. key is the path, value is a dict {'ip':visits}
  stats = {}

  file_start = Time.parse '2000-01-01'
  logs.each do |f|
    file_end = File.atime f

    next if file_start > end_d or file_end < start_d

    cat_cmd = f.end_with?('gz') && "gunzip -c #{f}" || "cat #{f}"
    cmd = %Q[#{cat_cmd} | awk '{print $2, substr($5,2), $1$8}' | grep #{pattern}]
    result = `#{cmd}`

    result.each_line do |l|
      ip, t, addr = l.split

      d = Date._strptime(t, '%d/%b/%Y:%H:%M:%S')
      t = Time.mktime(d[:year], d[:mon], d[:mday], d[:hour], d[:min], d[:sec])

      next if t < start_d or t > end_d

      stats[addr] = {} unless stats.key? addr
      addr_stat = stats[addr]
      addr_stat[ip] = 0 unless addr_stat.key? ip
      addr_stat[ip] += 1
    end

    file_start = file_end
  end

  puts "pv\tuv\taddress"
  outputs = {}
  stats.each do |k,v|
    str = "#{v.inject(0) {|sum,pair| sum + pair[1]}}\t#{v.count}\t#{k}"
    outputs[str] = str.split[0].to_i
  end

  sorted = outputs.sort {|a,b| b[1]<=>a[1]}
  sorted.each do |p|
    puts p[0]
  end
end
