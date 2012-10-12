#!/usr/bin/env ruby
# encoding: utf-8

require "yaml"
env = 'development'
CONFIG = YAML.load_file('config/weibo.yml')[env]

require "rubygems"
require "./access_dispatcher"
require "./weibo_ext"
require "./crawler"
require "time"

def compact_stat(stat_dic)
  result = {}

  stat_dic.each do |k, v|
    result[k] = v if v > 1
  end

  result
end

def retrieve_followings
  users = ARGF.map {|l| l}
  crawler = WeiboCrawler.new

  count = {}
  compact_thresh = 50000

  pos = 0
  users.each do |u|
    uid = u.to_i
    crawler.update_user_following(uid) do |f|
      fid = f["id"]
      name = f['screen_name']
      key = "#{fid}&||&#{name}"
      count[key] = 0 unless count.include? key

      count[key] += 1

      if count.count >= compact_thresh
        count = compact_stat(count)
        compact_thresh += count.count
      end
    end
  end

  sorted = count.sort {|x,y| y[1] <=> x[1] }
  sorted[0...5000].each do |p|
    name = p[0].split('&||&')[1]
    puts "#{p[1]}\t#{name}"
  end
end

if $PROGRAM_NAME == __FILE__
  retrieve_followings
end

