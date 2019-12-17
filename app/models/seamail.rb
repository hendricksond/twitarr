# == Schema Information
#
# Table name: seamails
#
#  id          :bigint           not null, primary key
#  last_update :datetime         not null
#  subject     :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_seamails_subject  (to_tsvector('english'::regconfig, (subject)::text)) USING gin
#

class Seamail < ApplicationRecord
  include Searchable

  has_many :messages, -> { order(:id) }, class_name: 'SeamailMessage', inverse_of: :seamail
  has_many :user_seamails, inverse_of: :seamail, dependent: :destroy
  has_many :users, through: :user_seamails

  validates :subject, presence: true, length: { maximum: 200 }
  validate :validate_users
  validate :validate_messages

  def validate_users
    errors[:base] << 'Must send seamail to another user of Twit-arr' unless usernames.count > 1
    usernames.each do |username|
      errors[:base] << "#{username} is not a valid username" unless User.exist? username
    end
  end

  def validate_messages
    errors[:base] << 'Must include a message' if messages.empty?
    messages.each do |message|
      message.errors.full_messages.each { |x| errors[:base] << x } unless message.valid?
    end
  end

  def usernames=(usernames)
    super usernames.map { |x| User.format_username x }
  end

  def subject=(subject)
    super subject&.strip
  end

  def last_message
    messages.first.timestamp
  end

  def seamail_count
    messages.size
  end

  def mark_as_read(username)
    messages.each { |message| message.read_users.push(username) unless message.read_users.include?(username) }
    save
  end

  def self.create_new_seamail(author, to_users, subject, first_message_text, original_author)
    right_now = Time.now
    to_users ||= []
    to_users = to_users.map(&:downcase).uniq
    to_users << author unless to_users.include? author
    seamail = Seamail.new(usernames: to_users, subject: subject, last_update: right_now)
    seamail.messages << SeamailMessage.new(author: author, text: first_message_text, timestamp: right_now, read_users: [author], original_author: original_author)
    seamail.save if seamail.valid?
    seamail
  end

  def add_message(author, text, original_author)
    right_now = Time.now
    self.last_update = right_now
    save
    messages.create author: author, text: text, timestamp: right_now, read_users: [author], original_author: original_author
  end

  def self.search(params = {})
    search_text = params[:query].strip.downcase.gsub(/[^\w&\s@-]/, '')
    current_username = params[:current_username]
    criteria = Seamail.where(usernames: current_username).or({ usernames: /^#{search_text}.*/ },
                                                             '$text' => { '$search' => "\"#{search_text}\"" })
    limit_criteria(criteria, params).order_by(last_update: :desc)
  end

end
