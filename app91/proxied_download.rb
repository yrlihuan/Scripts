#!/usr/bin/env ruby

require "rubygems"
require "em-http-request"
require "eventmachine"

if $PROGRAM_NAME == __FILE__
  if ARGV.count < 2:
    puts "usage: proxied_download.rb <url> <number of threads> <proxy files>"
    exit 1
  end

  url = ARGV[0]
  threads_cnt = 5
  if ARGV.count == 2
    threads_cnt = ARGV[1].to_i
  end

  proxies = []
  2.upto(ARGV.length-1) do |i|
    File.read(ARGV[i]).each_line { |l| proxies << l.strip }
  end

  proxies.uniq!

  ind = 0
  success = 0
  failed = 0
  total = proxies.count

  EM.run do
    EM::Iterator.new(proxies, threads_cnt).each do |p, iter|
      i = ind += 1
      phost, pport = p.split(":")
      connection_opts = {
        :proxy => {
           :host => phost,
           :port => pport.to_i
        }
      }

      bytes = 1024 * 2 * rand
      # http = EventMachine::HttpRequest.new(url, connection_opts).get :head => {"Range" => "bytes=-#{bytes.to_i}"}
      http = EventMachine::HttpRequest.new(url, connection_opts).get
      http.callback do |client|
        code = client.response_header.status.to_i
        if code >= 200 and code < 400
          success += 1
        else
          failed += 1
        end

        #puts "success: #{p} (#{i}/#{total}) length: #{client.response.length} code: #{code}"
        sleep(rand * 2)

        if i == total
          EM.stop
        else
          iter.next
        end
      end

      http.errback do |client|
        failed += 1
        #puts "failed: #{p} (#{i}/#{total} code: #{client.response_header.status})"
        sleep(rand * 2)

        if i == total
          EM.stop
        else
          iter.next
        end
      end
    end
  end

  puts "success #{success}"
end
