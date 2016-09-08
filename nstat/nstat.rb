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

  OPTIONS=<<-EOS
    path:
      name: nstat path
      default: /usr/bin/nstat
      notes: Location to find nstat if it's not on the path
  EOS

  def build_report
    process_nstat_output(execute_command)

    report(@data)
  rescue BinaryNotFoundError => e
    error("Cannot find nstat binary", e.message)
  rescue InvalidOutputError => e
    alert("Invalid output received from nstat", e.message)
  end

  protected
  def nstat_executable
    @nstat_executable = option(:path).to_s.empty? ? "nstat": File.join(option(:path), "nstat")
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
      @data = JSON.parse(results[:output], symbolize_names: true)[:kernel]
    rescue JSON::JSONError => e
      raise(InvalidOutputError, e.message)
    end
  end
end
