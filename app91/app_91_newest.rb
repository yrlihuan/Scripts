#!/usr/bin/env ruby

if $PROGRAM_NAME == __FILE__
  urls = []
  puts ''
  puts '-' * 80
  puts "- #{Time.now}"
  puts '-' * 80
  puts ''
  1.upto(5) do |i|
    listurl = "http://app.91.com/game/iPhone/category/0_#{i}_5"
    cmd = %Q[curl -s '#{listurl}' | sed -n 's/.*a href="\\([^ ]*\\)" title=.下载软件.*$/\\1/p']
    urls += `#{cmd}`.split
    sleep(10)
  end

  urls.each do |url|
    cmd = %Q[curl -s "#{url}" | sed -n -e "s/^.*分享日期：\\([0-9: \\\\-]*\\).*$/\\1/p" -e "s/^.*<title>\\(.*\\)-iPhone.*<\\/title>.*$/\\1/p" -e "s/^.*下载次数：\\([0-9]*\\).*$/\\1/p"]
    arr = `#{cmd}`.split("\n")
    if arr.count == 3
      name = arr[0]
      down = arr[1]
      time = arr[2]
      puts "#{time}, #{name}, #{down}"
    elsif arr.count == 2
      name = arr[0]
      down = "itunes"
      time = arr[1]
      puts "#{time}, #{name}, #{down}"
    end

    sleep(10)
  end
end
