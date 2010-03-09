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
		LOG_DIRECT = Bdb::DB_LOG_DIRECT
		LOG_DSYNC  = Bdb::DB_LOG_DSYNC
		LOG_AUTO_REMOVE = Bdb::DB_LOG_AUTO_REMOVE
		LOG_IN_MEMORY = Bdb::DB_LOG_IN_MEMORY
		LOG_ZERO   = Bdb::DB_LOG_ZERO

		# returns the Bdb-object.
		def bdb_object()  @env  end
		# Opens a Btree in this Environment
		def btree file, *p, &e
			open Btree, file, *p, &e
		end 
		# Opens a Hash in this Environment
		def hash file, *p, &e
			open Hash, file, *p, &e
		end 
		# Opens a Recno in this Environment
		def recno file, *p, &e
			open Recno, file, *p, &e
		end 
		# Opens a Queue in this Environment
		def queue file, *p, &e
			open Queue, file, *p, &e
		end 
		# Opens a DB of unknown type in this Environment
		def unknown file, *p, &e
			open Unknown, file, *p, &e
		end 

		def transaction flags = nil, &e
			Transaction.new self, flags, &e
		end
		alias txn transaction

		# args:
		#   args[0] => dir
		#   args[1] => flags
		#   args[3] => mode
		# possible options (via Hash):
		#	  :dir, :flags, :mode, :log_config
		def initialize *args
			opts = ::Hash === args.last ? args.pop : {}
			opts = {:dir => args[0], :flags => args[1], :mode => args[2]}.update opts
			@dbs, @env = WeakHash.new, Bdb::Env.new( 0)
			@env.log_config opts[:log_config], 1  if opts[:log_config]
			@env.lg_bsize = opts[:lg_bsize]  if opts[:lg_bsize]
			begin @env.open opts[:dir]||'.', opts[:flags]|| INIT_TRANSACTION|CREATE, opts[:mode]||0
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
			@dbs.each{|k, db|db.close}
			@env.close
		end

		class << self
			alias open new
		end

		# Opens a Database.
		# see SBDB::DB, SBDB::Btree, SBDB::Hash, SBDB::Recno, SBDB::Queue
		def open type, file, *p, &e
			p.push ::Hash.new  unless ::Hash === p.last
			p.last[:env] = self
			(type || SBDB::Unkown).new file, *p, &e
		end
		alias db open
		alias open_db open

		# Returns the DB like open, but if it's already opened,
		# it returns the old instance.
		# If you use this, never use close. It's possible somebody else use it too.
		# The Databases, which are opened, will close, if the Environment will close.
		def [] file, *p, &e
			p.push ::Hash.new  unless ::Hash === p.last
			p.last[:env] = self
			name = String === p[0] ? p[0] : p.last[:name]
			flags = Fixnum === p[1] ? p[1] : p.last[:flags]
			type = Fixnum === p[2] ? p[2] : p.last[:type]
			@dbs[ [file, name, flags | CREATE]] ||= (type || SBDB::Unknown).new file, *p, &e
		end
	end
	Env = Environment
end
