class User < ActiveRecord::Base

  attr_accessible :username, :email, :phone, :password, :password_confirmation, :remember_me, :time_zone, :notify_email, :notify_sms
  devise :database_authenticatable, :registerable, :recoverable,
    :rememberable, :trackable, :validatable, :token_authenticatable,
    :confirmable, :lockable # :timeoutable, :omniauthable

  before_save { |user| user.email = email.downcase }

  has_many :games_user
  has_many :games, through: :games_user

  has_many :consoles_user
  has_many :consoles, through: :consoles_user

  has_many :play_times
  has_many :attendees

  has_many :friendships
  has_many :friends,
           :through => :friendships,
           :conditions => "status = 'accepted'",
           :order => :username

  has_many :requested_friends,
           :through => :friendships,
           :source => :friend,
           :conditions => "status = 'requested'",
           :order => :created_at

  has_many :pending_friends,
           :through => :friendships,
           :source => :friend,
           :conditions => "status = 'pending'",
           :order => :created_at

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  LETTERS_ONLY = /\A[a-zA-Z]+\z/

  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :username, :presence => true, format: { with: LETTERS_ONLY, :message => "is letters only" }, uniqueness: { case_sensitive: false }
  validates :phone, :presence => true, length: { minimum: 10, :message => "is full 10 digit cell number" }
  validates :time_zone, presence: true
  validates_inclusion_of :time_zone, in: ActiveSupport::TimeZone.zones_map(&:name)
  validate :password_length_requirement

  scope :with_game, -> (id) { joins(:games).where 'games.id = ?', id }
  scope :with_console, -> (id) { joins(:consoles).where 'consoles.id = ?', id }

  def password_length_requirement
    return unless password.present? and not password.length >= 8
    errors.add :password, "must be at least 8 characters long"
  end

  def gravatar_url(options = {})
    size = options[:size] || 42
    rating = options[:rating] || 'g'
    blank_avatar = "mm"

    # See https://en.gravatar.com/site/implement/images/ for additional options
    "https://www.gravatar.com/avatar/#{email_hash}?s=#{size}&r=#{rating}&d=#{blank_avatar}"
  end

  def email_hash
    Digest::MD5.hexdigest(email)
  end

end
