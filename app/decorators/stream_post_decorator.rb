# noinspection RubyResolve
class StreamPostDecorator < Draper::Decorator
  delegate_all
  include Twitter::Autolink

  MAX_LIST_LIKES = 5

  def to_hash(username = nil, options = {})
    result = {
        id: as_str(id),
        author: author,
        text: auto_link(text),
        timestamp: timestamp.to_i,
        photo: photo,
        likes: some_likes(username),
        mentions: mentions,
        entities: entities,
        hash_tags: hash_tags,
        parent_chain: parent_chain
    }
    if options.has_key? :remove
      options[:remove].each {|k| result.delete k }
    end
    result
  end

  def some_likes(username)
    favs = []
    unless username.nil?
      favs << 'You' if likes.include? username
    end
    if likes.count < MAX_LIST_LIKES
      favs += likes.reject { |x| x == username }
    else
      if likes.include? username
        favs << "#{likes.count - 1} other seamonkeys"
      else
        favs << "#{likes.count} seamonkeys"
      end
    end
    return nil if favs.empty?
    favs
  end

end
