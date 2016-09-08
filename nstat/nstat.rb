#################################################
# NStat
#
#   Report on network interface statistics (TCP/UDP)
#   collected via nstat (http://linux.die.net/man/8/rtacct)
#
# Created by Matt Chesler 2016-09-08
#################################################

class NStat < Scout::Plugin
  needs 'json'

  class BinaryNotFoundError < RuntimeError; end
  class InvalidOutputError < RuntimeError; end

  KEYS = {
    tcp: [
      :TcpActiveOpens,
      :TcpPassiveOpens,
      :TcpAttemptFails,
      :TcpEstabResets,
      :TcpInSegs,
      :TcpOutSegs,
      :TcpRetransSegs,
      :TcpInErrs,
      :TcpOutRsts,
      :TcpInCsumErrors
    ],
    udp: [
      :UdpInDatagrams,
      :UdpNoPorts,
      :UdpInErrors,
      :UdpOutDatagrams,
      :UdpRcvbufErrors,
      :UdpSndbufErrors,
      :UdpInCsumErrors,
      :UdpLiteInDatagrams,
      :UdpLiteNoPorts,
      :UdpLiteInErrors,
      :UdpLiteOutDatagrams,
      :UdpLiteRcvbufErrors,
      :UdpLiteSndbufErrors,
      :UdpLiteInCsumErrors
    ],
    udp6: [
      :Udp6InDatagrams,
      :Udp6NoPorts,
      :Udp6InErrors,
      :Udp6OutDatagrams,
      :Udp6RcvbufErrors,
      :Udp6SndbufErrors,
      :Udp6InCsumErrors,
      :UdpLite6InDatagrams,
      :UdpLite6NoPorts,
      :UdpLite6InErrors,
      :UdpLite6OutDatagrams,
      :UdpLite6RcvbufErrors,
      :UdpLite6SndbufErrors,
      :UdpLite6InCsumErrors
    ],
    ip: [
      :IpInReceives,
      :IpInHdrErrors,
      :IpInAddrErrors,
      :IpForwDatagrams,
      :IpInUnknownProtos,
      :IpInDiscards,
      :IpInDelivers,
      :IpOutRequests,
      :IpOutDiscards,
      :IpOutNoRoutes,
      :IpReasmTimeout,
      :IpReasmReqds,
      :IpReasmOKs,
      :IpReasmFails,
      :IpFragOKs,
      :IpFragFails,
      :IpFragCreates
    ],
    ip6: [
      :Ip6InReceives,
      :Ip6InHdrErrors,
      :Ip6InTooBigErrors,
      :Ip6InNoRoutes,
      :Ip6InAddrErrors,
      :Ip6InUnknownProtos,
      :Ip6InTruncatedPkts,
      :Ip6InDiscards,
      :Ip6InDelivers,
      :Ip6OutForwDatagrams,
      :Ip6OutRequests,
      :Ip6OutDiscards,
      :Ip6OutNoRoutes
    ],
    ip6ext: [
      :Ip6ReasmTimeout,
      :Ip6ReasmReqds,
      :Ip6ReasmOKs,
      :Ip6ReasmFails,
      :Ip6FragOKs,
      :Ip6FragFails,
      :Ip6FragCreates,
      :Ip6InMcastPkts,
      :Ip6OutMcastPkts,
      :Ip6InOctets,
      :Ip6OutOctets,
      :Ip6InMcastOctets,
      :Ip6OutMcastOctets,
      :Ip6InBcastOctets,
      :Ip6OutBcastOctets,
      :Ip6InNoECTPkts,
      :Ip6InECT1Pkts,
      :Ip6InECT0Pkts,
      :Ip6InCEPkts
    ],
    icmpin: [
      :IcmpInMsgs,
      :IcmpInErrors,
      :IcmpInCsumErrors,
      :IcmpInDestUnreachs,
      :IcmpInTimeExcds,
      :IcmpInParmProbs,
      :IcmpInSrcQuenchs,
      :IcmpInRedirects,
      :IcmpInEchos,
      :IcmpInEchoReps,
      :IcmpInTimestamps,
      :IcmpInTimestampReps,
      :IcmpInAddrMasks,
      :IcmpInAddrMaskReps
    ],
    icmpout: [
      :IcmpOutMsgs,
      :IcmpOutErrors,
      :IcmpOutDestUnreachs,
      :IcmpOutTimeExcds,
      :IcmpOutParmProbs,
      :IcmpOutSrcQuenchs,
      :IcmpOutRedirects,
      :IcmpOutEchos,
      :IcmpOutEchoReps,
      :IcmpOutTimestamps,
      :IcmpOutTimestampReps,
      :IcmpOutAddrMasks,
      :IcmpOutAddrMaskReps
    ],
    icmp6in: [
      :Icmp6InMsgs,
      :Icmp6InErrors,
      :Icmp6InCsumErrors,
      :Icmp6InDestUnreachs,
      :Icmp6InPktTooBigs,
      :Icmp6InTimeExcds,
      :Icmp6InParmProblems,
      :Icmp6InEchos,
      :Icmp6InEchoReplies,
      :Icmp6InGroupMembQueries,
      :Icmp6InGroupMembResponses,
      :Icmp6InGroupMembReductions,
      :Icmp6InRouterSolicits,
      :Icmp6InRouterAdvertisements,
      :Icmp6InNeighborSolicits,
      :Icmp6InNeighborAdvertisements,
      :Icmp6InRedirects,
      :Icmp6InMLDv2Reports
    ],
    icmp6out: [
      :Icmp6OutMsgs,
      :Icmp6OutErrors,
      :Icmp6OutDestUnreachs,
      :Icmp6OutPktTooBigs,
      :Icmp6OutTimeExcds,
      :Icmp6OutParmProblems,
      :Icmp6OutEchos,
      :Icmp6OutEchoReplies,
      :Icmp6OutGroupMembQueries,
      :Icmp6OutGroupMembResponses,
      :Icmp6OutGroupMembReductions,
      :Icmp6OutRouterSolicits,
      :Icmp6OutRouterAdvertisements,
      :Icmp6OutNeighborSolicits,
      :Icmp6OutNeighborAdvertisements,
      :Icmp6OutRedirects,
      :Icmp6OutMLDv2Reports,
      :Icmp6OutType133,
      :Icmp6OutType135,
      :Icmp6OutType143
    ]
  }

  PROTOCOLS = KEYS.keys.map{|k| k.to_s}

  OPTIONS=<<-EOS
    path:
      name: nstat Path
      default: /usr/bin/nstat
      notes: Location to find nstat if it's not on the path
    protocol:
      name: Protocol
      default: udp
      notes: Protocol to collect from #{PROTOCOLS.join(', ')}
  EOS

  def build_report
    error("Invalid protocol specified", option(:protocol)) unless PROTOCOLS.include?(option(:protocol).to_s.downcase)

    process_nstat_output(execute_command)

    report(@data)
  rescue BinaryNotFoundError => e
    error("Cannot find nstat binary", e.message)
  rescue InvalidOutputError => e
    alert("Invalid output received from nstat", e.message)
  end

  protected
  def nstat_executable
    @nstat_executable = option(:path).to_s.empty? ? "/usr/bin/nstat" : option(:path)
  end

  def nstat_bin
    raise(BinaryNotFoundError, nstat_executable) unless File.exist?(nstat_executable)
    nstat_executable
  end

  def execute_command
    command = "#{nstat_bin} -jaz"
    output = `#{command} 2>&1`
    exit_code = $?.to_i

    { exit_code: exit_code, output: output }
  end

  def process_nstat_output(results)
    raise(InvalidOutputError, results[:output].chomp) if results[:exit_code] != 0

    begin
      data = JSON.parse(results[:output], symbolize_names: true)[:kernel]
      @data = data.select {|k,v| KEYS[option(:protocol).downcase.to_sym].include?(k)}
    rescue JSON::JSONError => e
      raise(InvalidOutputError, e.message)
    end
  end
end
