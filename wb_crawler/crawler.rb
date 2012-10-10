#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "oauth"
require "./access_dispatcher"
require "./weibo"
require "./weibo_ext"

class WeiboCrawler
  def initialize
  end

  def users_show(user_ids)
    user_ids.each do |uid|
      params = {:user_id => uid}

      yield weibo_instance.users_show(params)
    end
  end

  def update_counts(ids)
    params = {:ids => ids.join(",")}
    counts = weibo_instance.counts(params)
    counts.each do |c|
      yield c
    end
  end

  def update_user_following(user_id)
    cursor = 0
    count = 200
    while true
      params = {:user_id => user_id, :cursor => cursor, :count => count}

      friends = weibo_instance.statuses_friends(params)

      friends['users'].each do |f|
        yield f
      end

      break if friends['next_cursor'] == 0

      cursor = friends['next_cursor']
    end
  end

  def update_user_timeline(user_id)
    max_id = -1
    batch_count = 50
    while true
      params = {:user_id => user_id, :count => batch_count}
      if max_id > 0
        params[:max_id] = max_id - 1
      end

      timeline = weibo_instance.user_timeline(params)

      updated = 0
      timeline.each do |status|
        updated += yield status
        max_id = status.id
      end

      break if updated != batch_count
    end
  end

  def update_reposts(status_id)
    page = 1
    successive_failure = 0
    batch_start = Time.now
    max_id = 0
    while true
      puts "reposts: page #{page}"
      params = {:id => status_id, :count => 200, :page => page}
      if max_id > 0
        params[:max_id] = max_id
      end

      begin
        reposts = weibo_instance.repost_timeline(params)
        page += 1
      rescue Exception => e
        puts e
        sleep 30
        next
      end

      if reposts.length == 0
        successive_failure += 1
        page -= 1

        if successive_failure < 8
          sleep 3
          next
        else
          break
        end
      end

      updated = 0
      reposts.each do |repost|
        updated += yield repost

        if max_id == 0
          max_id = repost.id
        end
      end

      break if updated == 0

      successive_failure = 0
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
        sleep 31
        next
      end

      updated = 0
      comments.each do |comment|
        updated += yield comment
      end

      break if updated == 0
    end
  end

  def update_trends_timeline(trend)
    params = {:trend_name => trend}
    timeline = weibo_instance.trends_timeline(params)

    timeline.each do |status|
      yield status
    end
  end

  def weibo_instance
    token, secret = AccessDispatcher.request_access
    oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
    oauth.authorize_from_access(token, secret)
    Weibo::Base.new(oauth)
  end
end


