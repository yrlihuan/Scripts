
class Utils
  def self.is_zombie(friends, followers, tweets)
    followers < 15 or friends/followers >= 10
  end
end
