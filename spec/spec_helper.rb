$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "mock_redis/lib"))

require_relative "../migrator.rb"

# include patched version of mock_redis
# that works with Redis::Distributed
require "mock_redis.rb"
