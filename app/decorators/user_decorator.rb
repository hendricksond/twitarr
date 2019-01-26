class UserDecorator < Draper::Decorator
  delegate_all

  def public_hash
    {
      username: username,
      display_name: display_name,
      email: email,
      current_location: current_location,
      number_of_tweets: number_of_tweets,
      number_of_mentions: number_of_mentions,
      room_number: room_number,
      real_name: real_name,
      pronouns: pronouns,
      home_location: home_location,
      last_photo_updated: last_photo_updated
    }
  end

  def gui_hash
    {
      username: username,
      display_name: display_name,
      last_photo_updated: last_photo_updated.to_ms
    }
  end
  
  def admin_hash
    {
      username: username,
      is_admin: is_admin,
      status: status,
      email: email,
      display_name: display_name,
      current_location: current_location,
      last_login: last_login&.to_ms,
      empty_password: empty_password?,
      last_photo_updated: last_photo_updated.to_ms,
      room_number: room_number,
      real_name: real_name,
      pronouns: pronouns,
      home_location: home_location
    }
  end

  def self_hash
    hsh = admin_hash
    hsh[:unnoticed_alerts] = unnoticed_alerts
    hsh
  end

  def alerts_meta
    {
      seamail_unread_count: seamail_unread_count,
      unnoticed_mentions: unnoticed_mentions,
      unnoticed_alerts: unnoticed_alerts,
      unnoticed_announcements: unnoticed_announcements,
      unnoticed_upcoming_events: unnoticed_upcoming_events
    }
  end

end
