#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"

require "yaml"
env = 'development'
CONFIG = YAML.load_file('config/weibo.yml')[env]

require "./access_dispatcher"
require "./weibo_ext"
require "./crawler"
require "./utils"

def filter
  uids = $stdin.map {|l| l.to_i}

  crawler = WeiboCrawler.new
  valid_users = []

  crawler.users_show(uids) do |user|
    followers = user['followers_count']
    friends = user['friends_count']
    tweets = user['statuses_count']

    next if Utils.is_zombie(friends, followers, tweets)

    valid_users << user['id']
  end

  valid_users
end

if $PROGRAM_NAME == __FILE__
  filter.each do |uid|
    puts uid
  end
end


