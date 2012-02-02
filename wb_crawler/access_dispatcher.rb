require "date"

MAX_REQUEST_PER_ID_PER_HOUR = 150

ACCESS_TOKENS = CONFIG["tokens"]

class AccessDispatcher
  @@last_access = Time.now - 100
  @@last_pos = ACCESS_TOKENS.size - 1

  def self.request_access

    now = Time.now
    min_interval = 3600.0 / ACCESS_TOKENS.size / MAX_REQUEST_PER_ID_PER_HOUR * 2
    request_interval = now - @@last_access
    # puts "interval min: #{min_interval}, actual: #{request_interval}"
    if request_interval < min_interval
      sleep(min_interval - request_interval)
    end

    @@last_access = Time.now
    @@last_pos = (@@last_pos + 1) % ACCESS_TOKENS.size

    return ACCESS_TOKENS[@@last_pos]["token"], ACCESS_TOKENS[@@last_pos]["secret"]
  end
end
