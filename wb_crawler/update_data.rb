require "rubygems"
require "rails"
require "weibo"
require "oauth"
require "access_dispatcher"
require "sequel"

CONFIG = YAML.load_file('config/weibo.yml')['development']
DB = Sequel.connect(CONFIG['database'])

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

if $PROGRAM_NAME == __FILE__
  crawler = WeiboCrawler.new

  crawler.update_user_timeline("2066785327") do |status|
    puts "#{status.id} #{status.text}"
    1
  end
end

