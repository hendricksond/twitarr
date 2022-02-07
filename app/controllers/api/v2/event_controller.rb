# frozen_string_literal: true

require 'csv'
module Api
  module V2
    class EventController < ApiController
      before_action :events_enabled
      before_action :login_required, only: [:follow, :unfollow, :mine, :mine_soon]
      before_action :tho_required, only: [:destroy, :update]
      before_action :fetch_event, only: [:update, :destroy, :ical, :follow, :unfollow, :show]

      def update
        @event.title = params[:title] if params.key? :title
        @event.description = params[:description] if params.key? :description
        @event.location = params[:location] if params.key? :location
        @event.start_time = Time.from_param(params[:start_time]) if params.key? :start_time
        @event.end_time = Time.from_param(params[:end_time]) if params.key? :end_time

        if @event.valid?
          @event.save
          render json: { status: 'ok', event: @event.decorate.to_hash(current_user, request_options), now: DateTime.current.to_ms }
        else
          render status: :bad_request, json: { status: 'error', errors: @event.errors.full_messages }
        end
      end

      def destroy
        if @event.destroy
          render json: { status: 'ok' }
        else
          render status: :bad_request, json: { status: 'error', error: @event.errors }
        end
      end

      def ical
        # Yes this is based off vcard. They're really similar!
        cal_string = "BEGIN:VCALENDAR\n"
        cal_string << "VERSION:2.0\n"
        cal_string << "PRODID:-//twitarrteam/twitarr//NONSGML v1.0//END\n"

        cal_string << "BEGIN:VEVENT\n"
        cal_string << "UID:#{@event.id}@twitarr.local\n"
        cal_string << "DTSTAMP:#{@event.start_time.strftime('%Y%m%dT%H%M%S')}\n"
        cal_string << "ORGANIZER:CN=JOCO Cruise\n"
        cal_string << "DTSTART:#{@event.start_time.strftime('%Y%m%dT%H%M%S')}\n"
        cal_string << "DTEND:#{@event.end_time.strftime('%Y%m%dT%H%M%S')}\n" if @event.end_time.present?
        cal_string << "SUMMARY:#{@event.title}\n"
        cal_string << "DESCRIPTION:#{@event.description}\n"
        cal_string << "LOCATION:#{@event.location}\n"
        cal_string << "END:VEVENT\n"

        cal_string << 'END:VCALENDAR'
        headers['Content-Disposition'] = "inline; filename=\"#{@event.title.parameterize.underscore}.ics\""

        render body: cal_string, content_type: 'text/vcard', layout: false
      end

      def follow
        if @event.follow(current_user.id)
          render json: { status: 'ok', event: @event.decorate.to_hash(current_user, request_options), now: DateTime.current.to_ms }
        else
          render status: :bad_request, json: { status: 'error', error: 'Unable to follow event.' }
        end
      end

      def unfollow
        @event.unfollow(current_user.id)
        render json: { status: 'ok', event: @event.decorate.to_hash(current_user, request_options), now: DateTime.current.to_ms }
      end

      def index
        filtered_query = Event.all.includes(:user_events).references(:user_events).map { |x| x.decorate.to_hash(current_user, request_options) }
        render json: { status: 'ok', total_count: filtered_query.length, events: filtered_query, now: DateTime.current.to_ms }
      end

      def show
        render json: { status: 'ok', event: @event.decorate.to_hash(current_user, request_options), now: DateTime.current.to_ms }
      end

      def mine
        day = Time.from_param(params[:day])
        events = day_query(day).where(user_events: { user_id: current_user.id })
        render json: event_list_output(day, events)
      end

      def mine_soon
        minutes = params[:minutes]&.to_i
        events = mine_soon_query(minutes)
        render json: { status: 'ok', events: events.map { |x| x.decorate.to_hash(current_user, request_options) }, minutes:, now: DateTime.current.to_ms }
      end

      def day
        day = Time.from_param(params[:day])
        events = day_query(day)
        render json: event_list_output(day, events)
      end

      private

      def day_query(day)
        Event.includes(:user_events).references(:user_events).where('start_time >= ? AND start_time <= ?', day.beginning_of_day, day.end_of_day)
      end

      def mine_soon_query(minutes)
        Event.includes(:user_events).references(:user_events).where('user_events.user_id = ? AND start_time >= ? AND start_time <= ?', current_user.id, Time.zone.now, Time.zone.now + minutes.minutes)
      end

      def event_list_output(day, events)
        { status: 'ok', events: events.map { |x| x.decorate.to_hash(current_user, request_options) }, today: day.to_ms, prev_day: (day - 1.day).to_ms, next_day: (day + 1.day).to_ms, now: DateTime.current.to_ms }
      end

      def fetch_event
        @event = Event.includes(:user_events).references(:user_events).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render status: :not_found, json: { status: 'error', id: params[:id], error: 'Event not found.' }
      end
    end
  end
end
