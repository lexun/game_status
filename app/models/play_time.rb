class PlayTime < ActiveRecord::Base

  include ActionView::Helpers::DateHelper

  attr_accessible :start_time, :duration_text, :game_id, :console_id, :user_id, :notify
  attr_writer :start_time
  attr_writer :duration_text

  belongs_to :user
  belongs_to :game
  belongs_to :console
  has_many :attendees

  scope :future,      lambda { where('play_times.end > ?', Time.zone.now) }
  scope :past,        lambda { where('play_times.end < ?', Time.zone.now) }
  scope :most_recent, lambda { order('created_at desc').limit(1) }

  validates :game_id, :console_id, :presence => true
  validate :check_start_time, :check_duration_text

  before_save :save_start_time, :save_duration_text
  before_create :set_duration

  # start_time virtual attribute
  def start_time
    Chronic.time_class = Time.zone
    @start_time || Chronic.parse(self.start)
  end

  def save_start_time
    Chronic.time_class = Time.zone
    self.start = Chronic.parse(@start_time) if @start_time.present?
  end

  def check_start_time
    Chronic.time_class = Time.zone
    if !@start_time.present?
      errors.add "Start time", "(at) is required"
    elsif @start_time.present? && Chronic.parse(@start_time).nil?
      errors.add "Start time", "invalid, try something like '6pm' or '10:15am'"
    end
  rescue ArgumentError
    errors.add "Start time", "is out of range"
  end

  # duration_text virtual attribute
  def duration_text
    @duration_text || ""
  end

  def save_duration_text
    Chronic.time_class = Time.zone
    self.end = Chronic.parse(@duration_text + " from " + @start_time) if @duration_text.present?
  end

  def check_duration_text
    Chronic.time_class = Time.zone
    if !@duration_text.present?
      errors.add "Duration", "(for) is required"
    elsif @duration_text.present? && Chronic.parse(@duration_text + " from " + @start_time).nil?
      errors.add "Duration", "invalid, try something like '2 hrs' or '90 mins'"
    end
  rescue ArgumentError
    errors.add "Duration", "is out of range"
  end


  def in_progress?
    return true if self.start < Time.zone.now && self.end > Time.zone.now
    return false
  end

  def responded?(user_id)
    attendee = self.attendees.find_by_user_id(user_id)
  end

  def attending?(user_id)
    attendee = self.attendees.find_by_user_id(user_id)
    return attendee.attending if attendee
  end

  def notify?
    return self.notify
  end

  def duration_in_hours_minutes
    q, r = self.duration.divmod(60)
    words = ''

    if q == 1
      words = q.to_s + 'hr'
    elsif q != 0
      words = q.to_s + 'hrs'
    end

    if r == 1
      words += ' ' + r.to_s + 'min'
    elsif r > 1
      words += ' ' + r.to_s + 'mins'
    end
    return words
  end

  def distance_of_time
    self.in_progress? ? "Right Now!" : 'in ' + distance_of_time_in_words_to_now(self.start)
  end

private

  def set_duration
    self.duration = (self.end - self.start) / 60 
  end

end
