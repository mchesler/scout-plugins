#################################################
# Logstash
#
#   Collect and report on logstash metrics
#
# Created by Matt Chesler 2018-05-21
#################################################

class Logstash < Scout::Plugin
  needs 'net/http'
  needs 'resolv'
  needs 'json'

  OPTIONS = <<-EOF
    stats_host:
      default: 'localhost'
      name: Retrieve stats from host
      notes: Should generally be localhost
    stats_port:
      default: '9600'
      name: Stats Port
      notes: The port that will be queried for JSON formatted stats.
    stats_path:
      default: '_node/stats'
      name: Stats Path
      notes: The path for the stats endpoint.
  EOF

  def build_report
    stats_url  = "http://#{option(:stats_host)}:#{option(:stats_port)}/#{option(:stats_path)}"
    response   = Net::HTTP.get_response URI.parse(stats_url)
    raw_stats  = JSON.parse(response.body)
    result     = {}

    counter('events_in', raw_stats['events']['in'], :per => :second)
    counter('events_out', raw_stats['events']['out'], :per => :second)

    result['jvm_thread_count'] = raw_stats['jvm']['threads']['count']
    result['jvm_heap_max_in_bytes'] = raw_stats['jvm']['mem']['heap_max_in_bytes']
    result['jvm_heap_used_in_bytes'] = raw_stats['jvm']['mem']['heap_used_in_bytes']
    result['jvm_non_heap_used_in_bytes'] = raw_stats['jvm']['mem']['non_heap_used_in_bytes']
    result['jvm_gc_old_collection_time'] = raw_stats['jvm']['gc']['collectors']['old']['collection_time_in_millis']
    result['jvm_gc_young_collection_time'] = raw_stats['jvm']['gc']['collectors']['young']['collection_time_in_millis']
    result['jvm_uptime'] = raw_stats['jvm']['uptime_in_millis']
    result['events_duration'] = raw_stats['events']['duration_in_millis']
    result['events_queue_push_duration'] = raw_stats['events']['queue_push_duration_in_millis']
    result['input_current_connections'] = raw_stats['pipelines']['main']['plugins']['inputs'][0]['current_connections']
    result['input_peak_connections'] = raw_stats['pipelines']['main']['plugins']['inputs'][0]['peak_connections']
    result['queue_events'] = raw_stats['pipelines']['main']['queue']['events']
    result['queue_size_in_bytes'] = raw_stats['pipelines']['main']['queue']['capacity']['queue_size_in_bytes']
    result['queue_max_size_in_bytes'] = raw_stats['pipelines']['main']['queue']['capacity']['max_queue_size_in_bytes']

    report result
  end
end
