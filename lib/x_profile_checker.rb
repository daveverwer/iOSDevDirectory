require 'erb'
require 'faraday'
require 'json'
require 'parallel'

module XProfileChecker
  Issue = Struct.new(:title, :author, :url, :detail, keyword_init: true)

  module_function

  def check(blogs_path)
    data = JSON.parse(File.read(blogs_path))

    entries = []
    data.each do |language|
      language['categories'].each do |category|
        category['sites'].each do |site|
          next unless site['x_url']
          entries << site
        end
      end
    end

    puts "Checking #{entries.size} X/Twitter profiles via oembed endpoint..."

    conn = Faraday.new do |f|
      f.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      f.options.timeout = 10
      f.options.open_timeout = 5
    end

    checked = 0
    mutex = Mutex.new

    issues = Parallel.map(entries, in_threads: 10) do |site|
      result = check_profile(conn, site)

      mutex.synchronize do
        checked += 1
        print "\r  #{checked}/#{entries.size} checked..." if checked % 25 == 0
      end

      result
    end.compact

    puts "\n"
    [issues.uniq(&:url), entries.size]
  end

  def check_profile(conn, site)
    url = site['x_url']
    response = conn.get('https://publish.twitter.com/oembed', { url: url })

    if response.status >= 400
      Issue.new(title: site['title'], author: site['author'], url: url, detail: "HTTP #{response.status}")
    end
  rescue Faraday::ConnectionFailed => e
    Issue.new(title: site['title'], author: site['author'], url: url, detail: "Connection failed: #{e.message}")
  rescue Faraday::TimeoutError
    Issue.new(title: site['title'], author: site['author'], url: url, detail: 'Timeout')
  rescue Faraday::Error => e
    Issue.new(title: site['title'], author: site['author'], url: url, detail: e.message)
  end

  def render_text(issues, _total_checked)
    issues.sort_by { |i| i.title.downcase }.map(&:url).join("\n")
  end

  def render_html(issues, total_checked)
    sorted = issues.sort_by { |i| i.title.downcase }
    timestamp = Time.now.utc.strftime('%Y-%m-%d %H:%M UTC')
    h = ->(s) { escape_html(s) }

    template_path = File.join(__dir__, 'templates', 'x_profile_report.html.erb')
    template = ERB.new(File.read(template_path), trim_mode: '-')
    template.result(binding)
  end

  def escape_html(str)
    str.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
  end
end
