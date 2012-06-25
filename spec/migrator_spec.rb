describe Redis::Migrator do
  
  before do
    Redis.should_receive(:new).any_number_of_times {|options|  
      MockRedis.new(options) 
    }
  
    @migrator = Redis::Migrator.new(["localhost:6379", "localhost:6378"],
                                    ["localhost:6379", "localhost:6378", "localhost:6377"])

    @migrator.populate_keys(('a'..'z').to_a)
  end

  it "should show keys which need migration" do
    @migrator.changed_keys.sort.should == ["h", "j", "m", "n", "o", "q", "s", "y"]
  end

  it "should migrate given keys to a new cluster" do
    keys = ["q", "s", "j"]

    @migrator.migrate_keys(keys)

    (@migrator.new_cluster.keys("*") & keys).sort.should == ["j", "q", "s"]
    (@migrator.old_cluster.keys("*") & keys).sort.should == []
  end

  it "should migrate all keys for which nodes have changed" do
    @migrator.migrate_cluster

    (@migrator.old_cluster.keys("*") & @migrator.changed_keys).should == []
    (@migrator.new_cluster.keys("*") & @migrator.changed_keys).should == @migrator.changed_keys
  end
  
end

describe "copying redis keys" do 
  before do
    @r1 = MockRedis.new
    @r2 = MockRedis.new
  end

  it "should copy a string" do
    @r1.set("a", "some_string")
    Redis::Migrator.copy_string(@r1, @r2, "a")

    @r2.get("a").should == "some_string"
  end

  it "should copy a hash" do
    @r1.hmset("myhash", 
      "first_name", "James",
      "last_name", "Randi",
      "age", "83")

    Redis::Migrator.copy_hash(@r1, @r2, "myhash")

    @r2.hgetall("myhash").should == {"first_name" => "James", "last_name" => "Randi", "age" => "83"}
  end

  it "should copy a list" do
    ('a'..'z').to_a.each { |val| @r1.lpush("mylist", val) }

    Redis::Migrator.copy_list(@r1, @r2, "mylist")

    @r2.lrange("mylist", 0, -1).should == ('a'..'z').to_a
  end

  it "should copy a set" do
    ('a'..'z').to_a.each { |val| @r1.sadd("myset", val) } 

    Redis::Migrator.copy_set(@r1, @r2, "myset")

    @r2.smembers("myset").should == ('a'..'z').to_a
  end

  it "should copy zset" do
    ('a'..'z').to_a.each { |val| @r1.zadd("myzset", rand(100), val) } 

    Redis::Migrator.copy_zset(@r1, @r2, "myzset")

    @r2.zrange("myzset", 0, -1, :with_scores => true).should == @r1.zrange("myzset", 0, -1, :with_scores => true)
  end

end