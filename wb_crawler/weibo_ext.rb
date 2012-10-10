require "rubygems"
require "weibo"

module Weibo
  class Base
    def repost_timeline(query = {})
      perform_get('/statuses/repost_timeline.json', :query => query)
    end

    def trends_timeline(query = {})
      perform_get('/trends/statuses.json', :query => query)
    end

    def counts(query={})
      perform_get("/statuses/counts.json", :query => query)
    end

    def statuses_friends(query={})
      perform_get("/statuses/friends.json", :query => query)
    end

    def statuses_comments(query={})
      perform_get("/statuses/comments.json", :query => query)
    end

    def users_show(query={})
      perform_get("/users/show.json", :query => query)
    end
  end
end

