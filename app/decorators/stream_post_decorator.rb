# noinspection RubyResolve
class StreamPostDecorator < BaseDecorator
  delegate_all
  include ActionView::Helpers::DateHelper

  def to_hash(username = nil, options = {})
    result = {
        id: as_str(id),
        author: {
          username: author,
          display_name: User.display_name_from_username(author),
          last_photo_updated: User.last_photo_updated_from_username(author)
        },
        timestamp: timestamp.to_ms,
        text: twitarr_auto_linker(replace_emoji(clean_text_with_cr(text, options), options), options),
        reactions: BaseDecorator.reaction_summary(reactions, username),
        parent_chain: parent_chain
    }
    unless photo.blank?
      begin
        result[:photo] = { id: photo, animated: PhotoMetadata.find(photo).animated }
      rescue Mongoid::Errors::DocumentNotFound
      end
    end
    if options.has_key? :remove
      options[:remove].each { |k| result.delete k }
    end
    result
  end

end
