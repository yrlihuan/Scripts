#!/usr/bin/env ruby

require "rubygems"
require "json"
require "time"

def ftime(t)
  t.strftime("%H:%M:%S")
end

def latest_bid(id)
  data = `curl -s "http://auction.jd.com/json/paimai/bid_records?t=#{Time.now.to_i}173&dealId=#{id}&pageNo=1&pageSize=8"`
  data = JSON.load(data)

  data['datas'][0] || {}
end

def display_bids(id, bid_limit, end_time)

  `open "http://auction.jd.com/detail/#{id}"`

  puts "will end at: #{ftime(end_time)}"

  last_price = 0.0
  now = Time.now
  while end_time > now
    bid = latest_bid(id)
    price = bid['price']
    ip = bid['ipAddress']
    if price != last_price
      last_price = price
      puts "#{price}\t#{ftime(now)}\t#{ip}"
    end

    # if we are very close to auction deadline
    if end_time - now < 5
      if last_price < bid_limit
        my_bid = last_price * 1.01
        my_bid = my_bid.to_i

        if my_bid == last_price
          my_bid += 2
        end

        `echo "#{my_bid}" | pbcopy`
      else
        `echo "#{last_price-1}" | pbcopy`
      end
    end

    sleep(0.25)
    now = Time.now
  end
end

def run(config)
  last_display = Time.now - 60*10
  e_time = {}
  original_p = {}
  config.each do |id, bid|
    # retrieve end time
    html = `curl -s "http://auction.jd.com/detail/#{id}"`
    unless /endTimeMili:([0-9]*)\}/ =~ html
      puts "end time not found!"
      next
    end

    e_time[id] = Time.at($1.to_i / 1000)

    /del.￥([0-9.]*).\/del>/ =~ html
    original_p[id] = $1
  end

  while true
    now = Time.now
    if now - last_display > 60*5
      puts '-' * 60
      puts Time.now
      e_time.each do |id, t|
        if t > now
          seconds = (t-now).to_i
          p = latest_bid(id)['price']
          puts "http://auction.jd.com/detail/#{id} #{config[id]} #{p} #{original_p[id]} %s, (%02d:%02d)" % [t, seconds/60, seconds%60]
        end
      end

      puts ''
      last_display = now
    end

    e_time.each do |id, t|
      if t > now and t - now < 60:
        display_bids(id, config[id], t)
      end


    end

    sleep(10)
  end
end

if $PROGRAM_NAME == __FILE__
  config = {
    "3193253" => 480,
    "3193190" => 600,
    "3193002" => 460,
    "3192933" => 580,
    "3194226" => 380,
    "3194329" => 440,
    "3193094" => 500,
    "3192982" => 1300,
    "3193113" => 460,
  }

  run(config)
end

