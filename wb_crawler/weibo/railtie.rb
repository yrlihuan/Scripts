module Weibo
  class Railtie < Rails::Railtie
    config.after_initialize do
      if File.exists?('config/weibo.yml')
        weibo_oauth = YAML.load_file(File.join(Rails.root.to_s, 'config', 'weibo.yml'))[Rails.env || "development"]
        Weibo::Config.api_key = weibo_oauth["api_key"]
        Weibo::Config.api_secret = weibo_oauth["api_secret"]
      end
    end
    rake_tasks do
      load "weibo/tasks/weibo.rake"
    end
  end
end
