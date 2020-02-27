module Api
  module V2
    class UserController < ApiController
      before_action :registration_enabled, only: [:new]
      before_action :profile_enabled, only: [:show, :update_profile, :reset_photo, :update_photo]
      before_action :seamail_enabled, only: [:new_seamail]
      before_action :events_enabled, only: [:upload_schedule]
      before_action :login_required, only: [:new_seamail, :whoami, :star, :starred, :personal_comment, :update_profile, :change_password, :reset_photo, :update_photo, :mentions, :upload_schedule]
      before_action :not_muted, only: [:update_photo]
      before_action :fetch_user, only: [:show, :star, :personal_comment, :photo]

      def new
        if logged_in?
          render status: :bad_request, json: { status: 'error', errors: { general: ['Already logged in - log out before creating a new account.'] } }
          return
        end

        new_username = params[:new_username].present? ? params[:new_username].downcase : ''
        display_name = params[:display_name]
        display_name = params[:new_username] if params[:display_name].blank?
        user = User.new(username: new_username, display_name: display_name, password: params[:new_password],
                        role: User::Role::USER, status: User::ACTIVE_STATUS, registration_code: params[:registration_code])

        if user.invalid?
          render status: :bad_request, json: { status: 'error', errors: user.errors.messages }
          return
        end

        user.change_password params[:new_password]
        user.update_last_login
        user.save
        User.all_user_ids(true)
        login_user user
        render json: { status: 'ok', key: build_key(user.username, user.password), user: UserDecorator.decorate(user).self_hash }
      end

      def auth
        login_result = validate_login params[:username], params[:password]

        if login_result.key?(:error)
          render status: :unauthorized, json: { status: 'error', error: login_result[:error] }
          return
        end

        @user = login_result[:user]
        login_user @user
        render json: { status: 'ok', username: @user.username, key: build_key(@user.username, @user.password) }
      end

      def reset_password
        params[:username] ||= ''
        params[:registration_code] ||= ''
        user = User.where(username: User.format_username(params[:username])).first

        if user.nil? || user.registration_code != params[:registration_code].upcase.gsub(/[^A-Z0-9]/, '')
          sleep 10.seconds.to_i
          render status: :bad_request, json: { status: 'error', errors: { username: ['Username and registration code combination not found.'] } }
          return
        end

        # Check validity of new password
        new_pass = params[:new_password]
        user.password = new_pass

        if user.invalid?
          render status: :bad_request, json: { status: 'error', errors: { password: ['New password must be at least six characters long.'] } }
          return
        end

        user.change_password params[:new_password]
        user.save!
        render json: { status: 'ok', message: 'Your password has been changed.' }
      end

      def new_seamail
        render json: { status: 'ok', email_count: current_user.seamail_unread_count }
      end

      def auto_complete
        params[:query] ||= ''
        query = params[:query].downcase
        query = query[1..-1] if query[0] == '@'

        unless query && query.size >= User::MIN_AUTO_COMPLETE_LEN
          render status: :bad_request, json: { status: 'error', error: "Minimum length is #{User::MIN_AUTO_COMPLETE_LEN}" }
          return
        end

        render json: { status: 'ok', users: User.auto_complete(query).map { |x| x.decorate.gui_hash } }
      end

      def whoami
        render json: { status: 'ok', user: UserDecorator.decorate(current_user).self_hash, need_password_change: current_user.correct_password?(User::RESET_PASSWORD) }
      end

      def show
        hash = @user.decorate.public_hash(current_user).merge(
          recent_tweets: StreamPost.where(author: @user.id).order(id: :desc).limit(10).map { |x| x.decorate.to_hash(current_user, request_options) }
        )
        render json: { status: 'ok', user: hash }
      end

      def star
        starred = current_user.user_stars.find_by(starred_user_id: @user.id)
        if starred
          starred.delete
        else
          current_user.user_stars << UserStar.new(starred_user_id: @user.id)
        end
        render json: { status: 'ok', starred: !starred }
      end

      def starred
        users = current_user.starred_users.includes(:commented_by_users).references(:commented_by_users)
        hash = users.map do |u|
          uu = u.decorate.gui_hash
          uu.merge!(comment: u.commented_by_users.filter { |x| x.user_id == current_user.id }.first&.comment)
          uu
        end
        render json: { status: 'ok', users: hash }
      end

      def personal_comment
        if !params[:comment].nil? && params[:comment].length > 5000
          render status: :bad_request, json: { status: 'error', error: 'Comment is too long (maximum is 5000 characters)' }
          return
        end

        @user.comment(current_user.id, params[:comment])
        render json: { status: 'ok', user: @user.decorate.public_hash(current_user) }
      end

      def update_profile
        # current_user.current_location = params[:current_location] if params.has_key? :current_location

        # Muted users are allowed to set fields to blank or make no change, but they are not allowed to change fields to new text
        muted_change = false
        if params.key?(:display_name)
          current_user.display_name = params[:display_name] unless muted_change ||= (muted? && params[:display_name].present? && current_user.display_name != params[:display_name])
          current_user.display_name = current_user.username if current_user.display_name.blank?
        end

        if params.key?(:email)
          current_user.email = params[:email] unless muted_change ||= (muted? && params[:email].present? && current_user.email != params[:email])
        end

        if params.key?(:home_location)
          current_user.home_location = params[:home_location] unless muted_change ||= (muted? && params[:home_location].present? && current_user.home_location != params[:home_location])
        end

        if params.key?(:real_name)
          current_user.real_name = params[:real_name] unless muted_change ||= (muted? && params[:real_name].present? && current_user.real_name != params[:real_name])
        end

        if params.key?(:pronouns)
          current_user.pronouns = params[:pronouns] unless muted_change ||= (muted? && params[:pronouns].present? && current_user.pronouns != params[:pronouns])
        end

        current_user.show_pronouns = params[:show_pronouns].to_bool if params.key?(:show_pronouns)

        if params.key?(:room_number)
          current_user.room_number = params[:room_number] unless muted_change ||= (muted? && params[:room_number].present? && current_user.room_number != params[:room_number])
        end

        if !current_user.valid? || muted_change
          current_user.errors.add(:general, 'You have been muted. You may set fields to blank, but you may not otherwise change them.') if muted_change
          render status: :bad_request, json: { status: 'error', errors: current_user.errors }
          return
        end

        current_user.save
        render json: { status: 'ok', user: UserDecorator.decorate(current_user).self_hash }
      end

      def change_password
        errors = {}

        errors[:current_password] = ['Current password is incorrect.'] unless params[:current_password] && current_user.correct_password?(params[:current_password])

        current_user.password = params[:new_password]

        errors[:new_password] = ['New password must be at least six characters long, and cannot be more than 100 characters long.'] unless current_user.valid?

        if errors.empty?
          current_user.change_password params[:new_password]
          current_user.save
          render json: { status: 'ok', key: build_key(current_user.username, current_user.password) }
        else
          render status: :bad_request, json: { status: 'error', errors: errors }
        end
      end

      def photo
        response.headers['Etag'] = @user.photo_hash
        expires_in 1.second

        if params[:full]
          send_file @user.full_profile_picture_path, disposition: 'inline'
        else
          send_file @user.profile_picture_path, disposition: 'inline'
        end
      end

      def reset_photo
        render json: current_user.reset_photo
      end

      def update_photo
        unless params[:file]
          render status: :bad_request, json: { status: 'error', error: 'Must provide photo to upload.' }
          return
        end

        results = current_user.update_photo(params[:file])
        if results.fetch(:status) == 'error'
          render status: :bad_request, json: results
        else
          render json: results
        end
      end

      def mentions
        render json: { status: 'ok', mentions: current_user.unnoticed_mentions }
      end

      def upload_schedule
        begin
          upload = params[:schedule].tempfile.read
          temp = upload.gsub(/&amp;/, '&').gsub(/(?<!\\);/, '\;')
          Icalendar::Calendar.parse(temp).first.events.map { |x| Event.favorite_from_ics(x, current_user.id) }
        rescue StandardError => e
          render status: :bad_request, json: { status: 'error', error: "Unable to parse schedule: #{e.message}" }
          return
        end
        render json: { status: 'ok' }
      end

      def logout
        logout_user
        render json: { status: 'ok' }
      end

      private

      def fetch_user
        @user = User.get params[:username]
        render status: :not_found, json: { status: 'error', error: 'User not found.' } unless @user
      end
    end
  end
end
