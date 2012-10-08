#!/usr/bin/env ruby


if $PROGRAM_NAME == __FILE__
  cmd = %q[curl -s "http://app.91.com/Soft/iPhone/com.xingxinghui.game.musicguess-1.0-1.0.html" | sed -n "s_^.*<li>.*\(http://app.91.com/Soft/iPhone/com.xingxinghui.game.musicguess-.*html\).*_\1_p" | sort]
  urls = `#{cmd}`.split
  ver = urls.map {|url| url[url.rindex('-')+1...-5].split('.').inject(0) {|sum, c| sum * 100 + c.to_i}}
  newest = ver.sort.last
  index = ver.index(newest)
  url = urls[index]
  version = url[url.rindex('-')+1...-5]

  cmd = %Q[curl -s "#{url}" | grep "下载次数：" | sed -n "s/.*下载次数：\\([0-9]*\\).*/\\1/p"]
  result = `#{cmd}`
  puts "#{Time.now}: #{version}, #{result}"
end
