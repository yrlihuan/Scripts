#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"

require "yaml"
env = 'development'
CONFIG = YAML.load_file('config/weibo.yml')[env]

require "./access_dispatcher"
require "./weibo_ext"
require "./crawler"

def timeline(uid)
  crawler = WeiboCrawler.new
  tweets = []

  crawler.user_timeline(uid) do |tweet|
    tweets << tweet['id']
  end

  tweets
end

if $PROGRAM_NAME == __FILE__
  uid = ARGV[0].to_i
  timeline(uid).each do |sid|
    puts sid
  end
end

