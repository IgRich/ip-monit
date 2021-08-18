class PingService
  IpPingStat = Struct.new(:min, :avg, :max, :mdev, :transmitted, :received, :package_loss_percents)
  TIME_STAT_FORMAT = /^\s*([\d.]+)\/([\d.]+)\/([\d.]+)\/([\d.]+)/
  PACKAGE_STAT_FORMAT = /^(\d+)[^\d]+(\d+)[^\d]+\d*[^\d]+(\d+)%.+$/

  def ping(ip_address, count = 20)
    output = `ping -c #{count} #{ip_address}`
    "#{output}"
  end

  def get_ping_stats(ip_address, count = 20)
    ping_output = ping(ip_address, count)
    package_stat_str = ping_output.match(/\n(.+packets transmitted.+)\n?/)&.[](1) || ''
    time_stat_str = ping_output.match(/rtt min\/avg\/max\/mdev =\s*(.+)\n/)&.[](1) || ''

    current_time_stat = IpPingStat.new
    fill_rtt_stats(current_time_stat, time_stat_str)
    fill_package_stats(current_time_stat, package_stat_str)

    current_time_stat
  end

  private

  def fill_rtt_stats(stats, rtt_stats_string)
    rtt_stats_string.match(TIME_STAT_FORMAT) do |m|
      stats.min = m.captures[0]
      stats.avg = m.captures[1]
      stats.max = m.captures[2]
      stats.mdev = m.captures[3]
    end
  end

  def fill_package_stats(stats, package_stats_string)
    package_stats_string.match(PACKAGE_STAT_FORMAT) do |m|
      stats.transmitted = m.captures[0]
      stats.received = m.captures[1]
      stats.package_loss_percents = m.captures[2]
    end
  end
end