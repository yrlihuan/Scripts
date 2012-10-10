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
TPCONFIG = YAML.load_file('../topics.yml')
DBURL = "mysql://#{DBCONFIG['db_user']}:#{DBCONFIG['db_pass']}@localhost/#{DBCONFIG['products']['liuxin']['db']}"

require "rubygems"
require "weibo"
require "oauth"
require "sequel"
require "time"
require "yaml"
require "open-uri"

require "./access_dispatcher"
require "./weibo_ext"
require "./crawler"

DB = Sequel.connect(DBURL)

DB.create_table? :wb_topics do
  Bignum  :status_id, :primary_key => true
  String  :topic
  String  :content
  String  :content_pic
  String  :content_pic_th
  DateTime :created_at
  String  :source
  String  :user_name
  String  :user_role
  String  :user_pic
  String  :user_role_id
  Integer :retweet_count
  Integer :comment_count
  TrueClass :selected
  index   :created_at
  index   :topic
end

def set_selected(topic, data)
  # select only if the topic appears in the weibo content
  return 0 unless data[:content].index(TPCONFIG[topic]["topic"])

  # don't select if content contains any negative keywords
  black_list = TPCONFIG[topic]["keywords"]["negative"]
  black_list.each do |n|
    return 0 if data[:content].index(n)
  end

  return 1
end

def set_data_for_status(tp, topic, status, start)
  id = status.id.to_i
  created_at = Time.parse(status.created_at)

  if tp.first(:status_id => id)
    nil
  # include all items created 1 day before warmup
  elsif created_at < start - 60 * 60 * 24
    nil
  else
    data = {}
    data[:status_id] = id
    data[:topic] = topic
    data[:content] = status.text
    data[:content_pic] = status.original_pic
    data[:content_pic_th] = status.thumbnail_pic
    data[:created_at] = created_at
    data[:source] = status.source[0...-4].sub(/<.*>/, "")
    data[:user_name] = status.user.screen_name
    data[:user_pic] = status.user.profile_image_url
    data[:selected] = set_selected(topic, data)

    data
  end
end

def retrieve_topic_timeline(topic)
  crawler = WeiboCrawler.new
  tp = DB[:wb_topics]

  config = TPCONFIG[topic]
  topic_name = config["topic"]
  topic_encoded = URI::encode(topic_name)
  roles = TPCONFIG[topic]["roles"]

  warmup_start = Time.parse(config["warmup_start"])

  crawler.update_trends_timeline(topic_encoded) do |status|
    data = set_data_for_status(tp, topic, status, warmup_start)
    if data
      data["user_role"] = roles["normal"]["description"]
      data["user_role_id"] = "normal"
      tp << data
      1
    else
      0
    end
  end
end

def retrieve_user_timeline(topic, user)
  crawler = WeiboCrawler.new
  tp = DB[:wb_topics]

  event_start = Time.parse(TPCONFIG[topic]["event_start"])
  event_end = Time.parse(TPCONFIG[topic]["event_end"])
  warmup_start = Time.parse(TPCONFIG[topic]["warmup_start"])

  roles = TPCONFIG[topic]["roles"]

  crawler.update_user_timeline(user["uid"]) do |status|
    data = set_data_for_status(tp, topic, status, warmup_start)
    if data
      data["user_role"] = roles[user["role"]]["description"]
      data["user_role_id"] = user["role"]
      tp << data
      1
    else
      0
    end
  end
end

def retrieve_data_for_topic(topic)
  config = TPCONFIG[topic]
  users = config["users"]
  roles = config["roles"]

  retrieve_topic_timeline(topic)
  users.each do |u|
    retrieve_user_timeline(topic, u)
  end
end

def retrieve_count_for_messages(topic)
  crawler = WeiboCrawler.new
  tp = DB[:wb_topics]

  while true
    items = tp.filter(:retweet_count => nil, :topic => topic).limit(50)

    ids = []
    items.each do |item|
      ids << item[:status_id]
    end

    break if ids.count == 0

    crawler.update_counts(ids) do |c|
      id = c.id
      comment_count = c.comments
      retweet_count = c.rt

      tp[:status_id=>id.to_i] = {:comment_count=>comment_count, :retweet_count=>retweet_count}
    end
  end

  tp[:comment_count=>nil] = {:comment_count=>0, :retweet_count=>0}
end

def copy_db
  `mysqldump -u statusnet081 -plooamysqlroot liuxin_stag wb_topics > wb_topics.db`
  `mysql -u statusnet081 -plooamysqlroot liuxin < wb_topics.db`
end

if $PROGRAM_NAME == __FILE__
  TPCONFIG.each do |k, v|
    t_end = Time.parse(v["event_end"])
    t_now = Time.now

    if t_end > t_now
      puts k
      retrieve_data_for_topic(k)
      retrieve_count_for_messages(k)
    end
  end
  copy_db
end

