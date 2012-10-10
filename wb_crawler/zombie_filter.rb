#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"

require "yaml"
PROFILE = "liuxin"
class Rails
  def self.env
    PROFILE
  end
end

CONFIG = YAML.load_file('config/weibo.yml')[PROFILE]

require "./access_dispatcher"
require "./weibo_ext"
require "./crawler"

def filter
  uids = ARGF.map {|l| l}

  crawler = WeiboCrawler.new
  valid_users = []

  crawler.users_show(uids) do |user|
    followers = user['followers_count']
    friends = user['friends_count']

    next if followers < 15 or friends/followers > 10

    valid_users << user['id']
  end

  valid_users
end

if $PROGRAM_NAME == __FILE__
  filter.each do |uid|
    puts uid
  end
end


