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

  def try_until_success(max_retry=10)
    success = false
    retries = 0
    until success or retries >= max_retry
      begin
        yield
        success = true
      rescue Exception => e
        warn e
        sleep 10
        retries += 1
      end
    end
  end

  def user_timeline(user_id)
    max_id = -1
    batch_count = 50
    while true
      params = {:user_id => user_id, :count => batch_count}
      if max_id > 0
        params[:max_id] = max_id - 1
      end

      timeline = nil

      try_until_success { timeline = weibo_instance.user_timeline(params) }

      next unless timeline
      break if timeline.count == 0

      timeline.each do |status|
        updated += yield status
        max_id = status.id
      end

      break if updated != batch_count
    end

  end

  def users_show(user_ids)
    user_ids.each do |uid|
      params = {:user_id => uid, :count => 1}

      user = nil
      try_until_success do
        timeline = weibo_instance.user_timeline(params)
        if timeline.count > 0
          user = timeline[0]['user']
        end
      end

      yield user if user
    end
  end

  def update_user_following(user_id)
    cursor = 0
    count = 200
    while true
      params = {:user_id => user_id, :cursor => cursor, :count => count}

      friends = nil
      try_until_success {friends = weibo_instance.statuses_friends(params)}

      break unless friends

      friends['users'].each do |f|
        yield f
      end

      break if friends['next_cursor'] == 0

      cursor = friends['next_cursor']
    end
  end

  def weibo_instance
    token, secret = AccessDispatcher.request_access
    oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
    oauth.authorize_from_access(token, secret)
    Weibo::Base.new(oauth)
  end
end


