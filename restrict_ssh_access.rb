#!/usr/bin/env ruby

require "rubygems"
require "optparse"

if $PROGRAM_NAME == __FILE__
  options = {}
  opts = OptionParser.new do |opts|
    opts.on("-b", "--block", "") do |date|
      options[:from] = Date.parse date
    end

    opts.on("-t", "--to [DATE]", "End date (yyyymmdd)") do |date|
      options[:to] = Date.parse date
    end
  end


end
