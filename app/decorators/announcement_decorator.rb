class AnnouncementDecorator < BaseDecorator
  delegate_all
  include Twitter::Autolink

  def to_hash
    {
        author: author,
        display_name: User.display_name_from_username(author),
        text: auto_link(clean_text_with_cr(text)),
        timestamp: timestamp
    }
  end

  def to_admin_hash
    {
        id: id.to_s,
        author: author,
        text: text,
        timestamp: timestamp,
        valid_until: valid_until.strftime('%F %l:%M%P')
    }
  end

end