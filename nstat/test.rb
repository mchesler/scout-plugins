require File.dirname(__FILE__) + "/../test_helper.rb"
require File.expand_path('../nstat.rb', __FILE__)

class NStatTest < Test::Unit::TestCase

  def setup
    @plugin = NStat.new(nil, {}, { path: '/usr/bin' })
  end

  def test_successful_run_with_no_errors
    @plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = @plugin.run()
    assert_equal [], res[:errors]
    assert_equal [], res[:alerts]
  end

  def test_unable_to_find_nstat
    File.stubs(:exist?).with('/usr/bin/nstat').returns(false).once

    res = @plugin.run()
    assert_equal "Cannot find nstat binary", res[:errors].first[:subject]
    assert_equal "/usr/bin/nstat", res[:errors].first[:body]
  end

  def test_failed_run_with_errors
    @plugin.stubs(:execute_command).returns({ exit_code: 1, output: '' })

    res = @plugin.run()
    assert_equal "Invalid output received from nstat", res[:alerts].first[:subject]
    assert_equal "", res[:alerts].first[:body]
  end

  def test_invalid_json
    @plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/bad_sample.json') })

    res = @plugin.run()
    assert_equal "Invalid output received from nstat", res[:alerts].first[:subject]
    assert_equal "757: unexpected token at 'not json\n'", res[:alerts].first[:body]
  end

  def test_valid_json
    @plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = @plugin.run()
    assert_equal [], res[:errors]
    assert_equal [], res[:alerts]
    assert res[:reports].first.is_a?(Hash)
    assert_equal 10115891, res[:reports].first[:UdpInErrors]
  end
end
