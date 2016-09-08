require File.dirname(__FILE__) + "/../test_helper.rb"
require File.expand_path('../nstat.rb', __FILE__)

class NStatTest < Test::Unit::TestCase

  def setup
    @plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'udp' })
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

  def test_invalid_protocol
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'gibberish' })

    res = plugin.run()
    assert_equal "Invalid protocol specified", res[:errors].first[:subject]
    assert_equal "gibberish", res[:errors].first[:body]
  end

  def test_tcp
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'tcp' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:TcpActiveOpens)
  end

  def test_udp
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'udp' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:UdpInDatagrams)
  end

  def test_udp6
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'udp6' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:Udp6InDatagrams)
  end

  def test_ip
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'ip' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:IpInReceives)
  end

  def test_ip6
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'ip6' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:Ip6InReceives)
  end

  def test_icmpin
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'icmpin' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:IcmpInMsgs)
  end

  def test_icmpout
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'icmpout' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:IcmpOutMsgs)
  end

  def test_icmp6in
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'icmp6in' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:Icmp6InMsgs)
  end

  def test_icmp6out
    plugin = NStat.new(nil, {}, { path: '/usr/bin', protocol: 'icmp6out' })
    plugin.stubs(:execute_command).returns({ exit_code: 0, output: File.read(File.dirname(__FILE__)+'/fixtures/sample.json') })

    res = plugin.run()
    assert res[:reports].first.has_key?(:Icmp6OutMsgs)
  end
end
