require "date"

MAX_REQUEST_PER_ID_PER_HOUR = 150

ACCESS_TOKENS = [["7af075fa4dad0474fb4a0bcf9dd6807f", "4f099251954ef835b4192c7d4e912647"],
                 ["080d3cd6aaa38da8adcb93d74fdad376", "a55fa354ca07d5114d1400555ea7a1e6"],
                 ["6435762c979fabafbfedd23f43bc93cf", "f0c4ed2b0c78ad8d965e639c2257b053"],
                 ["763456e81bca416bc61fbee738bd40e9", "ec440ea27098d81cb5e20d8df1cd8992"],
                 ["ec14756f18daeb6cf27d084b59ef898d", "b401b377d0b819e3590668afcef09d0c"],
                 ["acf83abcd0767cffb6e30b327ea345a8", "756638860fe96e6fc5d5b212fc87eae8"],
                 ["aa6fb2efe3496e97a3ddad9838617efa", "2add533633e019d47642b9f7492725e0"],
                 ["a36dcbc6a3c03cdd6b7235b12fc32ff0", "1b3c1c0172efe3a1b98ee8c65e5947da"],
                 ["b74cb2bb5261d556c190f67a7818a338", "ec7ca15004bba92a781e53f8eaa0714f"],
                 ["336bd4674303265125abeb86b52a04ad", "513918bb220513e5c3457bd6fb3f6fb0"],
                 ["40f8f77fc6128ae7cfc1c13475e99a7c", "18afccb22844a5e28af6a2194c1cd350"]]

class AccessDispatcher
  @@last_access = Time.now - 100
  @@last_pos = ACCESS_TOKENS.size - 1

  def self.request_access

    now = Time.now
    min_interval = 3600.0 / ACCESS_TOKENS.size / MAX_REQUEST_PER_ID_PER_HOUR * 1.2
    request_interval = now - @@last_access
    if request_interval < min_interval
      sleep(min_interval - request_interval)
    end

    @@last_access = Time.now
    @@last_pos = (@@last_pos + 1) % ACCESS_TOKENS.size

    return ACCESS_TOKENS[@@last_pos]
  end
end
