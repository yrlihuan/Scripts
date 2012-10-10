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
DBURL = "mysql://#{DBCONFIG['db_user']}:#{DBCONFIG['db_pass']}@localhost/#{DBCONFIG['products']['liuxin']['db']}"

require "rubygems"
require "./access_dispatcher"
require "./weibo_ext"
require "./crawler"
require "sequel"
require "time"

DB = Sequel.connect(DBURL)

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

def get_retweeters(status_id)
  crawler = WeiboCrawler.new

  crawler.update_reposts(status_id) do |repost|
    user = repost.user
    puts "#{user.screen_name}\t#{user.followers_count}\t#{user.statuses_count}\t#{user.location}"

    1
  end
end

def update_reposts
  crawler = WeiboCrawler.new

  table_statuses = DB[:wb_statuses]
  table_users = DB[:wb_users]
  status_ind = 0

  table_statuses.each do |status|
    next if status[:retweet]
    max_id = status[:updated_retweet_max]
    status_id = status[:id]
    new_max = max_id

    users = {}
    total = 0

    crawler.update_reposts(status_id) do |repost|
      id = repost.id.to_i

      if id < max_id
        0
      else
        new_max = id if id > new_max
        total += 1

        user = repost.user
        userid = user.id.to_i

        ios_count = is_source_from_ios(repost.source) && 1 || 0
        if users.key?(userid)
          users[userid][0] += 1
          users[userid][1] += ios_count
        else
          users[userid] = [1, ios_count, user]
        end

        1
      end
    end

    users.each do |id, data|
      count = data[0]
      ios_count = data[1]
      user = data[2]
      user_db = table_users[:id=>id]
      if user_db
        user_db[:retweet_count] += count
        user_db[:retweet_count_ios] += ios_count
        table_users[:id=>id] = user_db
      else
        table_users << {:id => id,
                        :followers_count => user.followers_count,
                        :follower => false,
                        :retweet_count => count,
                        :retweet_count_ios => ios_count,
                        :screen_name => user.screen_name}
      end
    end

    table_statuses[:id=>status_id] = {:updated_retweet_max => new_max}

    puts "retweets updated for #{status_id}(#{status_ind+=1}th). #{total} updated"

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
    old = 0

    crawler.update_status_comments(status_id) do |comment|
      id = comment.id.to_i

      if id < max_id
        # puts "#{id}, #{max_id}" if old == 0
        old += 1
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

def is_source_from_ios(source)
  # puts source unless source.include? "新浪微博"
  return false if source.include? "新浪微博"
  return true if source.include?("iPhone客户端") || source.include?("iPad客户端") || source.include?("Weico.iPhone版") || source.include?("微格iPhone客户端") || source.include?("微格iPad客户端")
  return false
end

if $PROGRAM_NAME == __FILE__
  update_user_timeline
  #update_comments
  update_reposts
  #get_retweeters("3412746022272885")
end

