require File.dirname(__FILE__) + "/../test_helper.rb"
require File.expand_path('../nsq_counters.rb', __FILE__)

class NSQCountersTest < Test::Unit::TestCase
  def setup
    @plugin = NSQCounters.new(nil, {}, { host: 'localhost', port: 4151 })
  end

  def teardown
    FakeWeb.clean_registry
  end

  def test_successful_run
    FakeWeb.register_uri(:get, 'http://localhost:4151/stats?format=json', body: File.read(File.dirname(__FILE__)+'/fixtures/sample.json'))
    res = @plugin.run()

    assert_equal(5, res[:reports][0][:num_topics])
    assert_equal(1, res[:reports][0][:min_channels_per_topic])
    assert_equal(6, res[:reports][0][:max_channels_per_topic])
    assert_equal(0, res[:reports][0][:min_depth_per_topic])
    assert_equal(0, res[:reports][0][:max_depth_per_topic])
    assert_equal(1, res[:reports][0][:min_clients_per_channel])
    assert_equal(4, res[:reports][0][:max_clients_per_channel])
    assert_equal(0, res[:reports][0][:min_depth_per_channel])
    assert_equal(0, res[:reports][0][:max_depth_per_channel])
  end
end
