require 'bdb'
require 'sbdb/environment'
require 'sbdb/db'
require 'sbdb/cursor'

module SBDB
	CREATE      = Bdb::DB_CREATE
	AUTO_COMMIT = Bdb::DB_AUTO_COMMIT

	def btree( *p)   Btree.new *p   end
	def hash( *p)    Hash.new *p    end
	def recno( *p)   Recno.new *p   end
	def queue( *p)   Queue.new *p   end 
	def unknown( *p) Unknown.new *p end
	alias open_db unknown
end
