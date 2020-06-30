require "option_parser"
require "http/client"
require "json"

VERSION = "0.3.0"

TIME_AT_LAUNCH = Time.utc.at_beginning_of_minute

cf = {
  "zone_id"    => ENV.fetch("CF_ZONE_ID", ""),
  "auth_email" => ENV.fetch("CF_AUTH_EMAIL", ""),
  "auth_key"   => ENV.fetch("CF_AUTH_KEY", ""),
}

params = {
  "start"  => (TIME_AT_LAUNCH - 6.minutes).to_s("%s"),
  "end"    => (TIME_AT_LAUNCH - 1.minutes).to_s("%s"),
  "sample" => "0.01",
}

requested_fields = nil

options = Hash(String, String | Bool | Int32 | Nil).new(0)
options["remove_empty"] = false

parser = OptionParser.new do |op|
  op.banner = "Feron retrieves Cloudflare access logs using Logpull API..\n" +
              "Usage: #{PROGRAM_NAME} [arguments]"
  op.on("-z ID", "--zone-id=ID", "Cloudflare Zone ID, defaults to CF_ZONE_ID env value, if present") { |v| cf["zone_id"] = v.to_s }
  op.on("-e EMAIL", "--auth-email=EMAIL", "Cloudflare Auth Email, defaults to CF_AUTH_EMAIL env value, if present") { |v| cf["auth_email"] = v.to_s }
  op.on("-k KEY", "--auth-key=KEY", "Cloudflare Auth Key, defaults to CF_AUTH_KEY env value, if present") { |v| cf["auth_key"] = v.to_s }
  op.on("-r RAYID", "--rayid=RAYID", "RayID to retrieve log event for. When present, percent, count, and start/end time are ignored") { |v| options["rayid"] = v.to_s }
  op.on("-s PERCENT", "--sample=PERCENT", "Sample percentage (1% = 0.01), defaults to 0.01") { |v| params["sample"] = v.to_s }
  op.on("-c NUM", "--count=NUM", "Number of log events to retrieve, unset by default") { |v| params["count"] = v.to_s }
  op.on("-f FIELDS", "--fields=FIELDS", "Comma delimited list of log event fields to include, defaults to whatever API returns by default, set to \"all\" for all available fields") { |v| requested_fields = v.to_s }
  op.on("--start EPOCH", "Timestamp (inclusive) formatted as UNIX EPOCH, must be no more than 7 days back, defaults to 6 minutes ago") { |v| params["start"] = v.to_s }
  op.on("--end EPOCH", "Timestamp (exclusive) formatted as UNIX EPOCH, must be at least 1 minute old, and later than --start, defaults to 1 minute ago") { |v| options["end"] = v.to_s }
  op.on("--exclude-empty", "Exclude empty log fields, defaults to false") { options["remove_empty"] = true }
  op.on("-h", "--help", "Show this help") { STDOUT.puts op; exit 0 }
  op.on("-v", "--version", "Display version") { STDOUT.puts "v#{VERSION}"; exit 0 }
  op.invalid_option do |opt|
    STDERR.puts "ERROR: '#{opt}' is not a valid option."
    STDERR.puts op
    exit 1
  end
  op.missing_option do |opt|
    STDERR.puts "ERROR: missing value for '#{opt}'"
    STDERR.puts op
    exit 1
  end
end
parser.parse(ARGV)

if cf["zone_id"].empty?
  STDERR.puts "ERROR: --zone-id must be passed, exiting.."
  STDERR.puts parser
  exit 1
end

def get_fields(config)
  headers = HTTP::Headers{
    "X-Auth-Email" => config["auth_email"],
    "X-Auth-Key"   => config["auth_key"],
  }
  url = "https://api.cloudflare.com/client/v4/zones/#{config["zone_id"]}/logs/received/fields"

  response = HTTP::Client.get(url, headers)
  fields = JSON.parse(response.body).as_h
  return fields.keys
end

def get_logs(params, config, options = {} of String => String | Int | Bool)
  headers = HTTP::Headers{
    "X-Auth-Email" => config["auth_email"],
    "X-Auth-Key"   => config["auth_key"],
  }
  url = "https://api.cloudflare.com/client/v4/zones/#{config["zone_id"]}/logs/received?"

  params = HTTP::Params.encode(params)

  HTTP::Client.get(url + params, headers) do |response|
    unless response.success?
      response.consume_body_io
      STDERR.puts "ERROR: (#{response.status_code}/#{response.status}) #{response.body}"
      return nil
    end
    response.body_io.each_line do |line|
      line_hash = JSON.parse(line).as_h
      if options["remove_empty"]
        line_hash.reject! { |k, v|
          v.to_s.empty?
        }
      end
      STDOUT.puts line_hash.to_json
    end
  end
end

def get_rayid(params, config, options = {} of String => String | Int | Bool)
  headers = HTTP::Headers{
    "X-Auth-Email" => config["auth_email"],
    "X-Auth-Key"   => config["auth_key"],
  }
  rayid = options.delete("rayid")
  url = "https://api.cloudflare.com/client/v4/zones/#{config["zone_id"]}/logs/rayids/#{rayid}?"

  params = HTTP::Params.encode(params)

  HTTP::Client.get(url + params, headers) do |response|
    unless response.success?
      response.consume_body_io
      STDERR.puts "ERROR: (#{response.status_code}/#{response.status}) #{response.body}"
      return nil
    end
    response.body_io.each_line do |line|
      line_hash = JSON.parse(line).as_h
      if options["remove_empty"]
        line_hash.reject! { |k, v|
          v.to_s.empty?
        }
      end
      STDOUT.puts line_hash.to_json
    end
  end
end

if requested_fields == "all"
  params["fields"] = get_fields(cf).join(',')
elsif requested_fields != nil
  params["fields"] = requested_fields.to_s
end

unless options["rayid"]
  get_logs(params, cf, options)
else
  params.delete("start")
  params.delete("end")
  params.delete("sample")
  params.delete("count")
  get_rayid(params, cf, options)
end
