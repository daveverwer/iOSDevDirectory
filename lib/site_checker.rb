require 'erb'
require 'faraday'
require 'faraday/follow_redirects'
require 'json'
require 'parallel'

module SiteChecker
  PARKING_PATTERNS = [
    /this domain is for sale/i,
    /buy this domain/i,
    /domain is parked/i,
    /this page is parked/i,
    /domain parking/i,
    /parked by/i,
    /this website is for sale/i,
    /is available for purchase/i,
    /sedoparking/i,
    /domainlapse/i,
    /hugedomains/i,
    /godaddy\.com\/forsale/i,
    /afternic\.com/i,
    /parkingcrew/i,
    /above\.com/i,
    /bodis\.com/i,
    /\bdan\.com\/buy-domain\b/i,
  ].freeze

  SECTIONS = {
    dead: { heading: 'Dead Sites', desc: 'Connection refused, DNS failure, 404/410', color: '#dc3545' },
    timeout: { heading: 'Timeout', desc: 'No response within 15 seconds', color: '#fd7e14' },
    ssl_error: { heading: 'SSL Errors', desc: 'Invalid or expired certificates', color: '#e83e8c' },
    server_error: { heading: 'Server Errors', desc: 'HTTP 5xx responses', color: '#6f42c1' },
    parked: { heading: 'Parked / Spam Domains', desc: 'Domain parking pages detected', color: '#d63384' },
    feed_broken: { heading: 'Broken Feeds', desc: 'Wrong content type returned', color: '#0dcaf0' },
  }.freeze

  Issue = Struct.new(:title, :author, :language, :category, :field, :url, :kind, :detail, keyword_init: true)

  module_function

  def check(blogs_path)
    data = JSON.parse(File.read(blogs_path))

    checks = []
    data.each do |language|
      language['categories'].each do |category|
        category['sites'].each do |site|
          checks << { site: site, language: language['title'], category: category['title'] }
        end
      end
    end

    puts "Checking #{checks.size} sites..."
    issues = Parallel.flat_map(checks, in_threads: 10) { |entry| check_site(entry) }
    [issues, checks.size]
  end

  def render_html(issues, total_checked)
    grouped = issues.group_by(&:kind)
    sections = SECTIONS
    timestamp = Time.now.utc.strftime('%Y-%m-%d %H:%M UTC')
    h = ->(s) { escape_html(s) }

    template_path = File.join(__dir__, 'templates', 'site_health_report.html.erb')
    template = ERB.new(File.read(template_path), trim_mode: '-')
    template.result(binding)
  end

  def escape_html(str)
    str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
  end

  def new_connection
    Faraday.new do |f|
      f.response :follow_redirects, limit: 5
      f.options.timeout = 15
      f.options.open_timeout = 10
    end
  end

  def make_request(conn, url, method)
    retries = 0
    begin
      if method == :head
        r = conn.head(url)
        [405, 403].include?(r.status) ? conn.get(url) : r
      else
        conn.get(url)
      end
    rescue Faraday::ConnectionFailed
      retries += 1
      raise unless retries <= 2

      sleep(retries)
      retry
    end
  end

  def check_site(entry)
    conn = new_connection
    check_url(conn, entry, 'site_url', method: :head) +
      check_url(conn, entry, 'feed_url', method: :get)
  end

  def check_url(conn, entry, field, method: :head)
    site = entry[:site]
    url = site[field]
    issue = ->(kind, detail) do
      Issue.new(title: site['title'], author: site['author'], language: entry[:language],
                category: entry[:category], field: field, url: url, kind: kind, detail: detail)
    end

    response = make_request(conn, url, method)

    if [404, 410].include?(response.status)
      [issue.call(:dead, "HTTP #{response.status}")]
    elsif response.status >= 500
      [issue.call(:server_error, "HTTP #{response.status}")]
    elsif response.status == 200 && field == 'site_url'
      body = response.body.to_s.empty? ? conn.get(url).body.to_s : response.body.to_s
      body = body[0, 51_200].encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      match = PARKING_PATTERNS.find { |p| body.match?(p) }
      match ? [issue.call(:parked, "matched: #{match.source}")] : []
    elsif response.status == 200 && field == 'feed_url'
      content_type = response.headers['content-type'].to_s.downcase
      if content_type.match?(/xml|rss|atom|json|text\/plain/)
        []
      else
        [issue.call(:feed_broken, "content-type: #{content_type}")]
      end
    else
      []
    end
  rescue Faraday::ConnectionFailed then [issue.call(:dead, 'connection failed')]
  rescue Faraday::TimeoutError then [issue.call(:timeout, 'request timed out')]
  rescue Faraday::SSLError then [issue.call(:ssl_error, 'SSL error')]
  rescue Faraday::Error, URI::InvalidURIError => e then [issue.call(:dead, e.class.name)]
  end
end
