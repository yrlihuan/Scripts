desc 'Show Weibo Configurations'
task :weibo => :environment do
  puts "Weibo API Key: #{Weibo::Config.api_key}"
  puts "Weibo API Secret: #{Weibo::Config.api_secret}"
end
