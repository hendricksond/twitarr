class Seamail
  include Mongoid::Document
  include Searchable

  field :sj, as: :subject, type: String
  field :us, as: :usernames, type: Array
  field :rd, as: :unread_users, type: Array
  field :up, as: :last_update, type: Time
  embeds_many :messages, class_name: 'SeamailMessage', store_as: :sm, order: :timestamp.desc, validate: false

  validates :subject, presence: true
  validate :validate_users
  validate :validate_messages

  index usernames: 1
  index unread_users: 1
  index({:subject => 'text', :'sm.tx' => 'text'})

  def validate_users
    errors[:base] << 'Must send email to another user of Twitarr' unless usernames.count > 1
    usernames.each do |username|
      unless User.exist? username
        errors[:base] << "#{username} is not a valid username"
      end
    end
  end

  def validate_messages
    errors[:base] << 'Must include a message' if messages.size < 1
    messages.each do |message|
      unless message.valid?
        message.errors.full_messages.each { |x| errors[:base] << x }
      end
    end
  end

  def display_names
    usernames.map { |x| User.display_name_from_username x }
  end

  def usernames=(usernames)
    super usernames.map { |x| User.format_username x }
  end

  def subject=(subject)
    super subject.andand.strip
  end

  def last_message
    messages.first.timestamp
  end

  def seamail_count
    messages.size
  end

  def mark_as_read(username)
    pull(:unread_users => username)
  end

  def reset_read(author)
    # noinspection RubyUnusedLocalVariable,RubyLocalVariableNamingConvention
    ur = usernames - [author]
    unread_users.clear
    unread_users.push *ur
    save!
  end

  def self.create_new_seamail(author, to_users, subject, first_message_text)
    right_now = Time.now
    to_users ||= []
    to_users << author
    seamail = Seamail.new(usernames: to_users, subject: subject, unread_users: to_users, last_update: right_now)
    seamail.messages << SeamailMessage.new(author: author, text: first_message_text, timestamp: right_now)
    if seamail.valid?
      seamail.save
    end
    seamail
  end

  def add_message(author, text)
    right_now = Time.now
    reset_read author
    self.last_update = right_now
    self.save
    messages.create author: author, text: text, timestamp: right_now
  end

  def self.search(params = {})
    params[:no_hashtags] = true
    current_username = params[:current_username]
    search_object = build_search_object(params)
    screenames = search_object[:screenames]
    text_query = search_object[:text]

    where(usernames: current_username).or({ :usernames.in => screenames }, { '$text' => { '$search' => "\"#{text_query}\"" } })
  end

end