class PositionFile

  def processed?(violation)
    pos_file_date = DateTime.parse(violation['created']).strftime("%Y-%m-%d")
    pos_file = "jfrog_siem_log_#{pos_file_date}.pos"
    created_date = DateTime.parse(violation['created']).strftime("%Y-%m-%dT%H:%M:%SZ")
    violation_entry = [created_date, violation['watch_name'], violation['issue_id']].join(',')
    processed = File.open(pos_file) do |f|
      f.find { |line| line.include? violation_entry }
    end
    return processed
  end

  def write(v)
    created_date = DateTime.parse(v['created']).strftime("%Y-%m-%dT%H:%M:%SZ")
    pos_file_date = DateTime.parse(v['created']).strftime("%Y-%m-%d")
    pos_file = "jfrog_siem_log_#{pos_file_date}.pos"
    File.open(pos_file, 'a') do |f|
      f << [created_date, v['watch_name'], v['issue_id']].join(',')
      f << "\n"
    end
  end
end