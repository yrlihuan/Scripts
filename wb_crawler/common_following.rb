#!/usr/bin/env ruby
# encoding: utf-8

# hacks here: we don't want to add dependency on rails
PROFILE = "liuxin"
class Rails
  def self.env
    PROFILE
  end
end

require "yaml"
CONFIG = YAML.load_file('config/weibo.yml')[PROFILE]
DBCONFIG = YAML.load_file('../site.yml')

require "rubygems"
require "./access_dispatcher"
require "./weibo_ext"
require "./crawler"
require "sequel"
require "time"

def retrieve_followings
  users = YAML.load_file('./users_all.yml')
  crawler = WeiboCrawler.new

  count = {}

  pos = 0
  users[0...4000].each do |u|
    puts pos += 1
    uid = u['login']
    crawler.update_user_following(uid) do |f|
      fid = f["id"]
      name = f['screen_name']
      key = "#{fid}&||&#{name}"
      count[key] = 0 unless count.include? key

      count[key] += 1
    end
  end

  sorted = count.sort {|x,y| y[1] <=> x[1] }
  sorted[0...500].each do |p|
    name = p[0].split('&||&')[1]
    puts "#{p[1]}\t#{name}"
  end
end

if $PROGRAM_NAME == __FILE__
  retrieve_followings
end

