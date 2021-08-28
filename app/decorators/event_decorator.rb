# frozen_string_literal: true

class EventDecorator < BaseDecorator
  delegate_all

  def to_hash(current_user = nil, options = {})
    result = {
      id: id,
      title: title,
      location: location,
      start_time: nil,
      end_time: nil,
      official: official,
      description: '',
      following: current_user.present? && user_events.any? { |x| x.user_id == current_user.id }
    }
    # If DST hasn't started yet and we're viewing events that begin after DST starts,
    # adjust the displayed event start/end times to appear as if DST had not yet begun
    if Time.new < Event::DST_START && start_time >= Event::DST_START
      result[:start_time] = (start_time + 1.hour).to_ms
      result[:end_time] = (end_time + 1.hour).to_ms if end_time.present?
    else
      result[:start_time] = start_time.to_ms
      result[:end_time] = end_time.to_ms if end_time.present?
    end

    result[:description] = format_text(description, options) if description.present?
    result
  end
end
