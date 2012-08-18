#!/usr/bin/env ruby

require "rubygems"

if $PROGRAM_NAME == __FILE__
  cnt = 0
  while true
    cnt += 1
    puts "#{Time.now} start round #{cnt}"

    print "#{Time.now} retrieving proxies: ...  "
    cmd = 'curl -s "http://elite-proxies.blogspot.com/" | sed -n -e "/<pre/,/Original/ p" | sed -n "1,/Original/ p" | sed -n -e "/^[0-9][0-9.:]*$/ p"'
    proxyfile = "/tmp/#{Time.now.strftime('%y%m%d_%H%M%S')}.txt"
    s = `#{cmd}`
    while s.length < 10
      sleep(300)
      s = `#{cmd}`
    end

    file = File.open(proxyfile, "w")
    file.write(s)
    file.close
    puts "done!"

    print "#{Time.now} retrieving download url: ...  "
    cmd = %q{curl -s "http://app.91.com/Soft/iPhone/com.xingxinghui.game.musicguess-1.0.1-1.0.1.html" | grep "下载到电脑" | sed -n 's/^.*a href="\([^ ]*\)".*$/\1/p'}
    path = `cmd`
    while path.length < 10
      sleep(300)
      path = `#{cmd}`
    end

    url = "http://app.91.com#{path}"
    puts "done!"

    print "#{Time.now} running ... ...  "
    cmd = "./proxied_download.rb #{url} 500 #{proxyfile}"
    success = `#{cmd}`
    puts "done!"

    puts "#{Time.now} result: #{success} visits"
    sleep(60)
  end
end

