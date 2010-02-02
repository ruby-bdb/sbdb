require 'bdb'
require 'sbdb/weakhash'
require 'sbdb/db'

module SBDB
	# Environments are for storing one or more databases and are important
	# if you want to work with more than one process on one database.
	# You needn't use Environment,  but it's usefull.
	class Environment
		INIT_TXN   = Bdb::DB_INIT_TXN
		INIT_LOCK  = Bdb::DB_INIT_LOCK
		INIT_LOG   = Bdb::DB_INIT_LOG
		INIT_MPOOL = Bdb::DB_INIT_MPOOL
		INIT_TRANSACTION = INIT_TXN | INIT_LOCK | INIT_LOG | INIT_MPOOL
		LOCKDOWN   = Bdb::DB_LOCKDOWN
		NOMMAP     = Bdb::DB_NOMMAP
		PRIVATE    = Bdb::DB_PRIVATE
		SYSTEM_MEM = Bdb::DB_SYSTEM_MEM
		TXN_NOSYNC = Bdb::DB_TXN_NOSYNC

		# returns the Bdb-object.
		def bdb_object()  @env  end
		# Opens a Btree in this Environment
		def btree( *p, &e)   Btree.new   *p[0...6], self, p[6..-1], &e end 
		# Opens a Hash in this Environment
		def hash( *p, &e)    Hash.new    *p[0...6], self, p[6..-1], &e end 
		# Opens a Recno in this Environment
		def recno( *p, &e)   Recno.new   *p[0...6], self, p[6..-1], &e end 
		# Opens a Queue in this Environment
		def queue( *p, &e)   Queue.new   *p[0...6], self, p[6..-1], &e end 
		# Opens a DB of unknown type in this Environment
		def unknown( *p, &e) Unknown.new *p[0...6], self, p[6..-1], &e end 

		def initialize dir = nil, flags = nil, mode = nil
			@dbs, @env = WeakHash.new, Bdb::Env.new( 0)
			begin @env.open dir || '.', flags || INIT_TRANSACTION | CREATE, mode || 0
			rescue Object
				close
				raise
			end

			return self  unless block_given?

			begin yield self
			ensure close
			end
			nil
		end

		# Close the Environment.
		# First you should close all databases!
		def close
			@dbs.each{|db|db.close}
			@env.close
		end

		class << self
			alias open new
		end

		# Opens a Database.
		# see SBDB::DB, SBDB::Btree, SBDB::Hash, SBDB::Recno, SBDB::Queue
		def open type, *p, &e
			(type || SBDB::Unkown).new *p[0...6], self, p[6..-1], &e
		end
		alias db open
		alias open_db open

		# Returns the DB like open, but if it's already opened,
		# it returns the old instance.
		# If you use this, never use close. It's possible somebody else use it too.
		# The Databases, which are opened, will close, if the Environment will close.
		def [] file, name = nil, type = nil, &e
			@dbs[ [file, name]] ||= (type || SBDB::Unkown).new file, name, nil, nil, nil, self, &e
		end
	end
	Env = Environment
end