# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

Rails.application.load_tasks

system_task = Rake::Task['test:system']
test_task = Rake::Task[:test]
test_task.enhance { system_task.invoke }
