# code is an adaptation of the twitter gem by John Nunemaker
# http://github.com/jnunemaker/twitter
# Copyright (c) 2009 John Nunemaker
#
# made to work with china's leading twitter service, 新浪微博

require 'forwardable'
require 'rubygems'
require 'oauth'
require 'hashie'
require 'httparty'


require 'weibo/oauth'
require 'weibo/oauth_hack'
require 'weibo/httpauth'
require 'weibo/request'
require 'weibo/config'
require 'weibo/base'


module Weibo
  class WeiboError < StandardError
    attr_reader :data

    def initialize(data)
      @data = data
      super
    end
  end
  class RepeatedWeiboText < WeiboError; end
  class RateLimitExceeded < WeiboError; end
  class Unauthorized      < WeiboError; end
  class General           < WeiboError; end

  class Unavailable       < StandardError; end
  class InformWeibo       < StandardError; end
  class NotFound          < StandardError; end
end

module Hashie
  class Mash
    # Converts all of the keys to strings, optionally formatting key name
    def rubyify_keys!
      keys.each{|k|
        v = delete(k)
        new_key = k.to_s.underscore
        self[new_key] = v
        v.rubyify_keys! if v.is_a?(Hash)
        v.each{|p| p.rubyify_keys! if p.is_a?(Hash)} if v.is_a?(Array)
      }
      self
    end
  end
end



if File.exists?('config/weibo.yml')
  weibo_oauth = YAML.load_file('config/weibo.yml')['development']
  Weibo::Config.api_key = weibo_oauth["api_key"]
  Weibo::Config.api_secret = weibo_oauth["api_secret"]
else 
  puts "\n\n=========================================================\n\n" +
       "  You haven't made a config/weibo.yml file.\n\n  You should.  \n\n  The weibo gem will work much better if you do\n\n" + 
       "  Please set Weibo::Config.api_key and \n  Weibo::Config.api_secret\n  somewhere in your initialization process\n\n" +
       "=========================================================\n\n"
end

begin
if Rails
  require 'weibo/railtie'
end
rescue
end
