require 'lib/db_connection_pool'

DbConnectionPool.instance.configure(Rails.application.config.db)