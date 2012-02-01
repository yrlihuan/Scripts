#!/usr/bin/env ruby

# hacks here: we don't want to add dependency on rails
class Rails
  def self.env
    "development"
  end
end

require "rubygems"
require "weibo"
require "oauth"
require "./access_dispatcher"
require "sequel"
require "time"

CONFIG = YAML.load_file('config/weibo.yml')['development']
DB = Sequel.connect(CONFIG['database'])

DB.create_table? :wb_statuses do
  String :id, :primary_key => true
  String :text
  TrueClass :retweet
  DateTime :created_at
end

DB.create_table? :wb_users do
  String :id, :primary_key => true
  Integer :followers_count
  Integer :retweet_count, :default => 0
  Integer :comment_count, :default => 0
  TrueClass :follower
end

class WeiboCrawler
  def initialize
  end

  def update_user_timeline(user_id)
    max_id = -1
    while true
      token, secret = AccessDispatcher.request_access
      oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
      oauth.authorize_from_access(token, secret)

      params = {:user_id => user_id, :count => 200}
      if max_id > 0
        params[:max_id] = max_id - 1
      end

      timeline = Weibo::Base.new(oauth).user_timeline(params)

      updated = 0
      timeline.each do |status|
        updated += yield status
        max_id = status.id
      end

      break if updated == 0
    end
  end
end

def update_user(user, follower)
  table_users = DB[:wb_users]

  if table_users.first(:id => user.id)
    0
  else
    table_users.insert(:id => user.id, :screen_name => user.screen_name, :followers_count => user.followers_count, :follower => follower)
    1
  end
end

def update_comments
  crawler
end

def update_user_timeline
  crawler = WeiboCrawler.new

  table_tweets = DB[:wb_statuses]
  updated = 0

  crawler.update_user_timeline(CONFIG['target_user']) do |status|
    if table_tweets.first(:id => status.id)
      0
    else
      retweet = status.retweeted_status != nil
      created_at = Time.parse(status.created_at)
      table_tweets.insert(:id => status.id, :text => status.text, :retweet => retweet, :created_at => created_at)
      updated += 1
      1
    end
  end

  puts "update user timeline: #{updated}"
end

if $PROGRAM_NAME == __FILE__
  update_user_timeline
  update_followers
end

