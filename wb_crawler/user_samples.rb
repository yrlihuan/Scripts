#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"

def random_select_users(cnt)
  valid = 0
  tried = 0
  uids = []
  while valid < cnt
    trial_id = rand(2000000000) + 1000000000
    url = "http://weibo.com/#{trial_id}"
    cmd = "curl -Is #{url}"
    header = `#{cmd}`
    tried += 1

    if header.include? 'inviteCode'
      uids << trial_id
      valid += 1
    end
  end

  puts "#{tried} url tried"

  uids
end

def usage()
  'user_samples.rb <number_of_user_desired>'
end

if $PROGRAM_NAME == __FILE__
  if ARGV.length != 1
    puts usage
    exit
  end

  cnt = ARGV[0].to_i

  uids = random_select_users(cnt)
  uids.each do |uid|
    puts uid
  end
end
