#################################################
# NSQ Topic/Channel Checker
#
#  Collect and report on nsq metrics, specifically
#  counts of:
#    topics,
#    min/max channels per topic,
#    min/max clients per channel,
#    min/max depth per topic
#    min/mac depth per channel
#
# Created by Matt Chesler 2018-05-22
#################################################

class NSQCounters < Scout::Plugin
  needs 'net/http'
  needs 'json'

  OPTIONS = <<-EOS
    host:
      default: localhost
      name: host
      notes: The host of nsqdadmin
    port:
      default: 4151
      name: port
      notes: The port of nsqdadmin
  EOS

  def build_report
    uri = URI("http://#{option(:host)}:#{option(:port)}/stats?format=json")
    stats = JSON.parse(Net::HTTP.get(uri))
    topic_count = stats['data']['topics'].length

    channels_per_topic = stats['data']['topics'].map { |t| t['channels'].length }
    depth_per_topic = stats['data']['topics'].map { |t| t['backend_depth'] }

    clients_per_channel = stats['data']['topics'].map { |t|
      t['channels'].map { |c| c['clients'].length }
    }.flatten.compact.uniq
    depth_per_channel = stats['data']['topics'].map { |t|
      t['channels'].map { |c| c['depth'] }
    }.flatten.compact.uniq

    report(
      num_topics: topic_count,
      min_channels_per_topic:  channels_per_topic.min,
      max_channels_per_topic:  channels_per_topic.max,
      min_depth_per_topic:     depth_per_topic.min,
      max_depth_per_topic:     depth_per_topic.max,
      min_clients_per_channel: clients_per_channel.min,
      max_clients_per_channel: clients_per_channel.max,
      min_depth_per_channel:   depth_per_channel.min,
      max_depth_per_channel:   depth_per_channel.max
    )
  end
end
