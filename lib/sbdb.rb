require 'bdb'
require 'sbdb/environment'
require 'sbdb/db'
require 'sbdb/cursor'
require 'sbdb/transaction'

module SBDB
	CREATE      = Bdb::DB_CREATE
	AUTO_COMMIT = Bdb::DB_AUTO_COMMIT
	RDONLY      = Bdb::DB_RDONLY
	READONLY    = RDONLY

	def btree( *p)   Btree.new *p   end
	def hash( *p)    Hash.new *p    end
	def recno( *p)   Recno.new *p   end
	def queue( *p)   Queue.new *p   end 
	def unknown( *p) Unknown.new *p end
	alias open_db unknown

	def raise_barrier *ps, &e
		e.call *ps
	rescue Object
		$stderr.puts [$!.class,$!,$!.backtrace].inspect
	end
end
