class IpMeasurement < Sequel::Model(DbConnection.connect[:ip_measurements])

  def self.make_report(address, date_from, date_to)
    rtt_stats_query = <<RTT_STATS_QUERY.gsub(/\s+/, " ").strip
      select min(min_rtt) FILTER ( WHERE min_rtt <> 0 )   as min_rtt,
         max(max_rtt)                  as max_rtt,
         avg(avg_rtt)                  as avg_rtt,
         avg(lost_package_percent)     as lost_package_percent,
         percentile_cont(0.5) within group (order by avg_rtt) median_rtt
       from ip_measurements
       where performed_at between ? and ?
         and address = ?;
RTT_STATS_QUERY

    rtt_standard_deviation_query = <<RTT_STANDARD_DEVIATION_QUERY.gsub(/\s+/, " ").strip
      select sum((avg_rtt - ?) ^ 2)/GREATEST(count(*)-1, 1) as deviation
      from ip_measurements
      where performed_at between ? and ? and address = ?
RTT_STANDARD_DEVIATION_QUERY

    rtt_stats = DbConnection.connect[rtt_stats_query, date_from, date_to, address].first
    return nil unless rtt_stats[:avg_rtt] || rtt_stats[:lost_package_percent]
    rtt_deviation = DbConnection.connect[rtt_standard_deviation_query, rtt_stats[:avg_rtt], date_from, date_to, address].first
    {
      min_rtt: rtt_stats[:min_rtt].round(2),
      max_rtt: rtt_stats[:max_rtt].round(2),
      avg_rtt: rtt_stats[:avg_rtt].round(2),
      lost_package_percent: rtt_stats[:lost_package_percent].round(2),
      median_rtt: rtt_stats[:median_rtt].round(2),
      rtt_deviation: rtt_deviation[:deviation].round(2)
    }
  end
end