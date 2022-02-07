require 'securerandom'

@BASE_DATE = Time.now - 1.day
puts "Using a base date of #{@BASE_DATE}"

def create_registration_code(code)
  RegistrationCode.add_code code
end

puts "Creating registration codes..."
RegistrationCode.delete_all
if RegistrationCode.count == 0
  # stub codes for built-in accounts
  create_registration_code Rails.configuration.default_users.admin_regcode
  create_registration_code Rails.configuration.default_users.official_regcode
  create_registration_code Rails.configuration.default_users.moderator_regcode

  (1..100).each { |i|
    create_registration_code "code#{i}"
  }
end

puts 'Creating default users...'
User.create_default_users

unless User.exist? 'kvort'
  puts 'Creating user kvort'
  user = User.new username: 'kvort', display_name: 'kvort', password: 'kvort1',
    role: User::Role::ADMIN, status: User::ACTIVE_STATUS, registration_code: 'code1'
  user.change_password 'kvort'
  user.save
end

unless User.exist? 'james'
  puts 'Creating user james'
  user = User.new username: 'james', display_name: 'james', password: 'james1',
    role: User::Role::USER, status: User::ACTIVE_STATUS, registration_code: 'code2'
  user.change_password 'james'
  user.save
end

unless User.exist? 'steve'
  puts 'Creating user steve'
  user = User.new username: 'steve', display_name: 'steve', password: 'steve1',
    role: User::Role::USER, status: User::ACTIVE_STATUS, registration_code: 'code3'
  user.change_password 'steve'
  user.save
end

kvort = User.get('kvort').id
james = User.get('james').id
steve = User.get('steve').id

unless User.exist? 'TwitarrTeam'
  raise Exception.new("No user named 'TwitarrTeam'!  Create one first!")
end

unless User.exist? 'official'
  raise Exception.new("No user named 'official'!  Create one first!")
end

unless User.exist? 'moderator'
  raise Exception.new("No user named 'moderator'!  Create one first!")
end

def add_photo(path, local_filename, uploader, upload_date)
  photo_basename = File.basename local_filename
  photo_md = PhotoMetadata.find_by(original_filename: photo_basename)
  return photo_md if photo_md

  puts "Using photo #{path} => #{photo_basename}"
  local_file = ActionDispatch::Http::UploadedFile.new(:tempfile => File.new(path),
                                                      :filename => photo_basename,
                                                      :type     => "image/jpeg"
                                                     )
  res = PhotoStore.instance.upload local_file, uploader
  photo_md = PhotoMetadata.find_by id: res[:photo]
  photo_md.created_at = upload_date
  photo_md.save!
  photo_md
end

def at_time(hr, min, params = {})
  dt = @BASE_DATE
  dt = dt + params[:offset] if params.has_key? :offset
  params.delete :offset
  params[:hour] = hr
  params[:min] = min
  dt.change params
end

photos = []
Dir.mktmpdir do |dir|
  photos.push add_photo('db/seeds/images/1.jpg', File.join(dir, 'cute_cat.jpg'), james, at_time(14, 30, offset: -1.day))
  photos.push add_photo('db/seeds/images/2.jpg', File.join(dir, 'mean_cat.jpg'), steve, at_time(12, 0))
  photos.push add_photo('db/seeds/images/3.jpg', File.join(dir, 'tired_cat.jpg'), james, at_time(12, 5))
  photos.push add_photo('db/seeds/images/4.jpg', File.join(dir, 'warm_bread.jpg'), kvort, at_time(11, 15))
end

def create_post(text, author, timestamp, photo)
  post = StreamPost.create(text: text, author: author, original_author: author, created_at: timestamp)
  post.post_photo = PostPhoto.create(photo_metadata_id: photo) if photo
  unless post.valid?
    puts "Errors for post #{text}: #{post.errors.full_messages}"
    return post
  end
  post.save!
  post
end

StreamPost.delete_all
if StreamPost.count == 0
  create_post 'This is a cute cat #catphotos', james, at_time(14, 31, offset:-1.day), photos[0].id
  create_post 'Joco is the best cruise ever #jococruise', steve, at_time(10, 9), nil
  create_post 'This cruise is coming up really soon #jococruise', james, at_time(10, 12), nil

  create_post 'The bread is warm #warmbread', james, at_time(10, 13), nil
  create_post 'Whats with the #warmbread meme?', steve, at_time(10, 14), nil
  create_post 'This is a mean cat #catphotos', steve, at_time(12, 1), photos[1].id
  create_post 'This is a tired cat #catphotos', james, at_time(12, 6), photos[2].id

  create_post 'Look at this #warmbread', kvort, at_time(11, 15), photos[3].id
  create_post 'Wow, that bread is warm #warmbread', james, at_time(11, 16), nil
  create_post 'I miss netflix.', steve, at_time(11, 17), nil

  create_post 'Are you, are you #mockingjay', kvort, at_time(11, 18), photos[3].id
  create_post 'Coming to the tree #mockingjay', james, at_time(11, 19), nil
  create_post 'Where they strung up a man they say murdered three #mockingjay', steve, at_time(11, 20), nil

  create_post 'Strange things did happen here #mockingjay', james, at_time(11, 21), nil
  create_post 'No stranger would it be #mockingjay', kvort, at_time(11, 22), nil
  create_post 'If we met at midnight in the hanging tree #mockingjay', steve, at_time(11, 23), nil

  create_post 'Are you, are you #mockingjay', kvort, at_time(11, 21), nil
  create_post 'Coming to the tree #mockingjay', steve, at_time(11, 22), nil
  create_post 'Where the dead man called out for his love to flee #mockingjay', james, at_time(11, 23), nil

  create_post 'Are you, are you #mockingjay', kvort, at_time(11, 21), nil
  create_post 'Coming to the tree #mockingjay', steve, at_time(11, 22), nil
  create_post 'Where the dead man called out for his love to flee #mockingjay', james, at_time(11, 23), nil


  create_post 'Are you, are you #mockingjay', james, at_time(11, 24), nil
  create_post 'Coming to the tree #mockingjay', kvort, at_time(11, 25), nil
  create_post 'Where the dead man called out for his love to flee #mockingjay', steve, at_time(11, 26), nil

  create_post 'Nike+ bracelet thingie verdict: it successfully guilted me into learning guitar by fighting zombies.', steve, at_time(11, 27), nil
  create_post 'I may have eaten too much #cake.', kvort, at_time(11, 28), nil
  create_post '@kvort you can never have too much #cake.', steve, at_time(11, 29), nil
  create_post '@kvort though you can never eat to much #cookies', james, at_time(11, 30), nil
  create_post '@james challenge accepted.', kvort, at_time(11, 31), nil
  create_post 'Whats the over/under?', steve, at_time(11, 32), nil
end

forum_photos = []
Dir.mktmpdir do |dir|
  forum_photos.push add_photo('db/seeds/images/5.jpg', File.join(dir, 'forum1_init_cat.jpg'), kvort, at_time(8, 5))
  forum_photos.push add_photo('db/seeds/images/6.jpg', File.join(dir, 'forum1_init2_cat.jpg'), kvort, at_time(8, 6))
  forum_photos.push add_photo('db/seeds/images/7.jpg', File.join(dir, 'forum1_post1_cat.jpg'), james, at_time(8, 15))
  forum_photos.push add_photo('db/seeds/images/8.jpg', File.join(dir, 'forum2_init1_food.jpg'), james, at_time(8, 20))
  forum_photos.push add_photo('db/seeds/images/9.jpg', File.join(dir, 'forum2_post2_food.jpg'), steve, at_time(8, 21))
  forum_photos.push add_photo('db/seeds/images/10.jpg', File.join(dir, 'forum2_post3_bread.jpg'), kvort, at_time(8, 22))
end

def create_forum(subject, text, author, timestamp, photos)
  #force photos to be an array!
  photos = [photos] unless photos.is_a? Array
  photos = photos.map { |p| p.id }
  forum = Forum.create_new_forum(author, subject, text, photos, author)
  post = forum.posts.first
  post.created_at = timestamp
  post.save!
  forum
end

def add_forum_post(forum, text, author, timestamp, photos)
  #force photos to be an array!
  photos = [photos] unless photos.is_a? Array
  photos = photos.map { |p| p.id }
  post = ForumPost.new_post forum.id, author, text, photos, author
  post.created_at = timestamp
  post.save!
  post
end

Forum.delete_all
if Forum.count == 0
  f = create_forum 'First forum', 'Hey guys this is the first forum entry. Lets talk about some #catphotos. ' +
                   '@james you should post some.', kvort, at_time(8, 6), [forum_photos[0], forum_photos[1]]
  add_forum_post f, '@kvort Alright here you go! #yetanothercat', james, at_time(8, 15), forum_photos[2]
  f = create_forum 'Food pictures are awesome', 'Hey guys lets post some of the awesome food here. #foodftw',
      james, at_time(8, 20), forum_photos[3]
  add_forum_post f, '@james I <3 food', steve, at_time(8, 20), forum_photos[4]
  add_forum_post f, '@steve @james I think this needs some #warmbread', kvort, at_time(8, 22), forum_photos[5]

  puts 'Spamming forums...'
  (0..100).each { |i|
    create_forum i.to_s, i.to_s, kvort, at_time(8, i % 60), []
  }
end

def create_seamail(subject, text, author, recipients, timestamp)
  seamail = Seamail.create_new_seamail author, recipients, subject, text, author
  seamail.last_update = timestamp
  seamail.created_at = timestamp
  seamail.updated_at = timestamp
  message = seamail.seamail_messages.first
  message.created_at = timestamp
  message.updated_at = timestamp
  message.save!
  seamail.save!
  seamail
end

def reply_seamail(seamail, text, author, timestamp)
  message = seamail.add_message author, text, author
  message.created_at = timestamp
  message.updated_at = timestamp
  message.save!
  message
end

Seamail.delete_all
if Seamail.count == 0
  puts 'Creating moderator seamail thread...'
  Seamail.create_moderator_seamail

  puts 'Creating additional seamail threads...'
  seamail = create_seamail 'Hey lets meet up', 'How about at 10:30?', 'james', ['kvort'], at_time(8, 23)
  reply_seamail seamail, 'Alright, 10-forward?', 'kvort', at_time(8, 26)
  reply_seamail seamail, 'Sounds great to me!', 'james', at_time(8, 28)
  seamail = create_seamail 'artemis?', 'We should go to the game room and play artemis at 15:00!', 'steve', ['kvort', 'james'], at_time(9, 23)
  reply_seamail seamail, 'Awesome!', 'james', at_time(9, 30)
end

puts 'Creating events...'
cal_filename = "db/seeds/all.ics"
# fix bad encoding from sched.org
cal_text = File.read(cal_filename)
cal_text = cal_text.gsub(/&amp;/, '&').gsub(/(?<!\\);/, '\;')
if File.exists? cal_filename + ".tmp"
  File.delete(cal_filename + ".tmp")
end
File.open(cal_filename + ".tmp", "w") { |file| file << cal_text }

cal_file = File.open(cal_filename + ".tmp")
Icalendar::Calendar.parse(cal_file).first.events.map { |x| Event.create_from_ics x }

def create_reaction(tag)
  reaction = Reaction.add_reaction tag
  reaction.save!
  reaction
end

puts 'Creating reactions...'
Reaction.delete_all
if Reaction.count == 0
  create_reaction 'like'
end

puts 'Creating sections...'
Section.repopulate_sections
