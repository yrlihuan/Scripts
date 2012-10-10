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

def commenters(count)
  sids = $stdin.map {|l| l.to_i}

  crawler = WeiboCrawler.new
  valid_users = {}

  sids.each do |sid|
    crawler.statuses_comments(sid) do |c|
      user = c['user']

      followers = user['followers_count']
      friends = user['friends_count']
      tweets = user['statuses_count']

      next if Utils.is_zombie(friends, followers, tweets)
      next if valid_users.key? user['id']

      valid_users[user['id']] = 0

      break if valid_users.count >= count
    end

    break if valid_users.count >= count
  end

  valid_users.keys
end

def usage
"""ruby tweet_commenters <desired number of non-zombie commenters>
"""
end

if $PROGRAM_NAME == __FILE__
  if ARGV.count != 1
    puts usage
    exit
  end

  commenters(ARGV[0].to_i).each do |uid|
    puts uid
  end
end


