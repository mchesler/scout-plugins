require File.dirname(__FILE__) + "/../test_helper.rb"
require File.expand_path('../logstash.rb', __FILE__)

class LogstashTest < Test::Unit::TestCase
  def setup
    @plugin = Logstash.new(nil, {}, { stats_host: 'localhost', stats_port: 9600, stats_path: '_node/stats' })
  end

  def teardown
    FakeWeb.clean_registry
  end

  def test_successful_run
    FakeWeb.register_uri(:get, 'http://localhost:9600/_node/stats', body: File.read(File.dirname(__FILE__)+'/fixtures/logstash_stats.json'))
    res = @plugin.run()
    assert_equal(43, res[:reports][0]['jvm_thread_count'])
  end
end
