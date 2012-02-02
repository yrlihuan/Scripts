require "rubygems"
require "weibo"

module Weibo
  class Base
    def repost_timeline(query = {})
      perform_get('/statuses/repost_timeline.json', :query => query)
    end
  end
end
