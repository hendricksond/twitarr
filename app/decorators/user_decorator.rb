# frozen_string_literal: true

class UserDecorator < Draper::Decorator
  delegate_all

  def public_hash(current_user = nil)
    ret = {
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
      last_photo_updated: last_photo_updated.to_ms
    }
    unless current_user.nil?
      ret[:starred] = current_user.user_stars.exists?(starred_user_id: id)
      ret[:comment] = current_user.user_comments.find_by(commented_user_id: id)&.comment
    end
    ret
  end

  def gui_hash
    {
      username: username,
      display_name: display_name,
      last_photo_updated: last_photo_updated.to_ms,
      pronouns: user.show_pronouns ? user.pronouns : ''
    }
  end

  def admin_hash
    ts = if last_login == Time.at(0)
           0
         else
           last_login.to_ms
         end
    {
      username: username,
      role: User::Role.as_string(role),
      # status: status,
      email: email,
      display_name: display_name,
      current_location: current_location,
      last_login: ts,
      empty_password: user.password.blank?,
      last_photo_updated: last_photo_updated.to_ms,
      room_number: room_number,
      real_name: real_name,
      pronouns: pronouns,
      show_pronouns: show_pronouns,
      home_location: home_location,
      mute_reason: mute_reason,
      ban_reason: ban_reason
    }
  end

  def self_hash
    hsh = admin_hash
    hsh.delete(:mute_reason)
    hsh.delete(:ban_reason)
    hsh
  end

  def alerts_meta
    {
      unnoticed_announcements: unnoticed_announcements,
      unnoticed_alerts: unnoticed_alerts,
      seamail_unread_count: seamail_unread_count,
      unnoticed_mentions: unnoticed_mentions,
      unnoticed_upcoming_events: unnoticed_upcoming_events
    }
  end
end
