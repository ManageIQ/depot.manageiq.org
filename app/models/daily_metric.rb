class DailyMetric < ActiveRecord::Base
  def self.increment(key, by = 1, day = Date.today)
    transaction do
      m = where(key: key, day: day).first_or_create
      DailyMetric.where(key: key, day: day).update_all("count = count + #{by}")
    end
  end

  def self.counts_since(key, since = Date.today - 1.week)
    counted = DailyMetric.where(key: key).where("day >= ?", since).to_a
    cur = since + 1.day
    counts = []

    while cur <= Date.today
      m = counted.find { |m| m.day == cur }

      if m
        counts << m.count
      else
        counts << 0
      end

      cur += 1.day
    end

    counts
  end
end
