#!/usr/bin/env ruby


if $PROGRAM_NAME == __FILE__
  cmd = 'curl -s "http://app.91.com/Soft/iPhone/com.xingxinghui.game.musicguess-1.0-1.0.html" | grep "下载次数：" | sed -n "s/.*下载次数：\([0-9]*\).*/\1/p"'
  result = `#{cmd}`
  puts "#{Time.now}: #{result}"
end
