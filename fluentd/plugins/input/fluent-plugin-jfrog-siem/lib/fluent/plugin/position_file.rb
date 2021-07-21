class PositionFile

  def initialize(pos_file_path)
    @pos_file_path = pos_file_path
  end

  def processed?(violation)
    File.exist?(pos_file_name(violation)) && found?(violation)
  end

  def found?(violation)
    return File.open(pos_file_name(violation)) { |f| f.find { |line| line.include? violation_entry(violation) } }
  end

  def write(violation)
    File.open(pos_file_name(violation), 'a') do |f|
      f << violation_entry(violation)
      f << "\n"
    end
  end

  def violation_entry(violation)
    created_date = DateTime.parse(violation['created']).strftime("%Y-%m-%dT%H:%M:%SZ")
    [created_date, violation['watch_name'], violation['issue_id']].join(',')
  end

  def pos_file_name(violation)
    pos_file_date = DateTime.parse(violation['created']).strftime("%Y-%m-%d")
    @pos_file_path + "jfrog_siem_log_#{pos_file_date}.siem.pos"
  end
end