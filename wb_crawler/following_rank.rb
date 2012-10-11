#!/usr/bin/env ruby
# encoding: utf-8

require "yaml"
env = 'development'
CONFIG = YAML.load_file('config/weibo.yml')[env]

require "rubygems"
require "./access_dispatcher"
require "./weibo_ext"
require "./crawler"
require "time"

def usage
"""ruby following_rank.rb <stat for specific account> <number of users for 1> <stat for common users> <number of users for 2>
"""
end

def read_stat_file(file, count)
  content = File.read(file)
  stat = {}

  content.each do |l|
    num, account = l.split
    stat[account] = num.to_f / count
  end

  stat
end

if $PROGRAM_NAME == __FILE__
  if ARGV.count != 4
    puts usage
    exit
  end

  file1 = ARGV[0]
  count1 = ARGV[1].to_i

  file2 = ARGV[2]
  count2 = ARGV[3].to_i

  stat1 = read_stat_file(file1, count1)
  stat2 = read_stat_file(file2, count2)

  ranks = {}
  minor_ranks = {}
  min2 = stat2.values.min - 1.0/count2

  stat1.each do |account, percent|
    if stat2.key? account
      rank = percent / stat2[account]

      ranks[account] = [rank, percent, stat2[account]]
    else
      rank = percent / min2
      minor_ranks[account] = [rank, percent, 0]
    end
  end

  stat2.each do |account, percent|
    unless stat1.key? account
      rank = 0

      ranks[account] = [rank, 0, percent]
    end
  end

  ranks = ranks.map {|l| l}.sort {|p1, p2| p2[1][0] <=> p1[1][0] }

  ranks.each do |account, tuple|
    puts "%.3f\t%.3f\t%.3f\t%s" % (tuple + [account])
  end

  puts "\n" + "-" * 40 + "\n"

  minor_ranks = minor_ranks.map {|l| l}.sort {|p1, p2| p2[1][0] <=> p1[1][0] }

  minor_ranks.each do |account, tuple|
    puts "%.3f\t%.3f\t%.3f\t%s" % (tuple + [account])
  end

end

