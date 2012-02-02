#!/usr/bin/env ruby

# hacks here: we don't want to add dependency on rails
PROFILE = "liuxin"
class Rails
  def self.env
    PROFILE
  end
end

require "yaml"
CONFIG = YAML.load_file('config/weibo.yml')[PROFILE]

require "rubygems"
require "weibo"
require "oauth"
require "./access_dispatcher"
require "./weibo_ext"
require "sequel"
require "time"

DB = Sequel.connect(CONFIG['database'])

DB.create_table? :wb_statuses do
  Bignum :id, :primary_key => true
  String :text
  TrueClass :retweet
  DateTime :created_at
  Bignum :updated_comment_max, :default => 0
  Bignum :updated_retweet_max, :default => 0
end

DB.create_table? :wb_users do
  Bignum :id, :primary_key => true
  Integer :followers_count
  Integer :retweet_count, :default => 0
  Integer :retweet_count_ios, :default => 0
  Integer :comment_count, :default => 0
  String :screen_name
  TrueClass :follower
end

class WeiboCrawler
  def initialize
  end

  def update_user_timeline(user_id)
    max_id = -1
    while true
      params = {:user_id => user_id, :count => 50}
      if max_id > 0
        params[:max_id] = max_id - 1
      end

      timeline = weibo_instance.user_timeline(params)

      updated = 0
      timeline.each do |status|
        updated += yield status
        max_id = status.id
      end

      break if updated == 0
    end
  end

  def update_status_comments(status_id)
    page = 1
    batch_start = Time.now
    while true
      puts "comments: page #{page}"
      params = {:id => status_id, :count => 200, :page => page}

      begin
        comments = weibo_instance.comments(params)
        # HACK: sina only allows to retrieve less than 500 records per minute
        if page % 3 == 1 && page != 1
          backoff_interval = batch_start - Time.now + 60.5
          sleep(backoff_interval) if backoff_interval > 0
          batch_start = Time.now
        end

        page += 1
      rescue Exception => e
        puts e
        sleep 5
        next
      end

      updated = 0
      comments.each do |comment|
        updated += yield comment
      end

      break if updated == 0
    end
  end

  def weibo_instance
    token, secret = AccessDispatcher.request_access
    oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
    oauth.authorize_from_access(token, secret)
    Weibo::Base.new(oauth)
  end
end

def update_comments
  crawler = WeiboCrawler.new

  table_statuses = DB[:wb_statuses]
  table_users = DB[:wb_users]
  status_ind = 0

  table_statuses.each do |status|
    max_id = status[:updated_comment_max]
    status_id = status[:id]
    new_max = max_id

    users = {}
    total = 0

    crawler.update_status_comments(status_id) do |comment|
      id = comment.id.to_i

      if id < max_id
        0
      else
        new_max = id if id > new_max
        total += 1

        user = comment.user
        userid = user.id.to_i
        if users.key?(userid)
          users[userid][0] += 1
        else
          users[userid] = [1, user]
        end

        1
      end
    end

    users.each do |id, data|
      count = data[0]
      user = data[1]
      user_db = table_users[:id=>id]
      if user_db
        user_db[:comment_count] += count
        table_users[:id=>id] = user_db
      else
        table_users << {:id => id, :followers_count => user.followers_count, :follower => false, :comment_count => count, :screen_name => user.screen_name}
      end
    end

    table_statuses[:id=>status_id] = {:updated_comment_max => new_max}

    puts "comments updated for #{status_id}(#{status_ind+=1}th). #{total} updated"
  end
end

def update_user_timeline
  crawler = WeiboCrawler.new

  table_tweets = DB[:wb_statuses]
  updated = 0

  crawler.update_user_timeline(CONFIG['target_user']) do |status|
    id = status.id.to_i
    if table_tweets.first(:id => id)
      0
    else
      retweet = status.retweeted_status != nil
      created_at = Time.parse(status.created_at)
      table_tweets << {:id => id, :text => status.text, :retweet => retweet, :created_at => created_at}
      updated += 1
      1
    end
  end

  puts "update user timeline: #{updated}"
end

if $PROGRAM_NAME == __FILE__
  #update_user_timeline
  #update_comments
end

