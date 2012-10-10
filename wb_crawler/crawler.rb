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

      success = false
      until success
        begin
          yield weibo_instance.users_show(params)
          success = true
        rescue Exception => e
          puts e
          sleep 30
        end
      end
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

  def weibo_instance
    token, secret = AccessDispatcher.request_access
    oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
    oauth.authorize_from_access(token, secret)
    Weibo::Base.new(oauth)
  end
end


