#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"

require "yaml"
env = 'development'
CONFIG = YAML.load_file('config/weibo.yml')[env]



if $PROGRAM_NAME == __FILE__
  uid = ARGV[0].to_i
  filter.each do |uid|
    puts uid
  end
end

