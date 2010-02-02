require 'bdb'
require 'sbdb/cursor'

module SBDB
	class DB
		UNKNOWN = Bdb::Db::UNKNOWN
		BTREE = Bdb::Db::BTREE
		HASH = Bdb::Db::HASH
		QUEUE = Bdb::Db::QUEUE
		ARRAY = RECNO = Bdb::Db::RECNO

		attr_reader :home
		include Enumerable
		def bdb_object()  @db  end
		def sync()  @db.sync  end
		def close( f = nil)  @db.close f || 0  end
		def []( k)  @db.get nil, k, nil, 0  end
		def []=( k, v)  @db.put nil, k, v, 0  end
		def cursor( &e)  Cursor.new self, &e  end

		class << self
			def new *p, &e
				x = super *p
				return x  unless e
				begin e.call x
				ensure
					x.sync
					x.close
				end
			end
			alias open new
		end

		def initialize file, name = nil, type = nil, flags = nil, mode = nil, txn = nil, env = nil
			flags ||= 0
			type ||= UNKNOWN
			type = BTREE  if type == UNKNOWN and (flags & CREATE) == CREATE
			@home, @db = env, env ? env.bdb_object.db : Bdb::Db.new
			begin @db.open txn, file, name, type, flags, mode || 0
			rescue Object
				close
				raise $!
			end
		end

		def each k = nil, v = nil, &e
			cursor{|c|c.each k, v, &e}
		end

		def reverse k = nil, v = nil, &e
			cursor{|c|c.reverse k, v, &e}
		end

		def to_hash k = nil, v = nil
			h = {}
			each( k, v) {|k, v| h[ k] = v }
			h
		end
	end

	class Unknown < DB
		def self.new *p, &e
			db = super *p[0...2], UNKNOWN, *p[2..-1]
			case db.bdb_object.get_type
			when BTREE  then Btree.new *p
			when HASH   then Hash.new  *p
			when RECNO  then Recno.new *p
			when QUEUE  then Queue.new *p
			else super *p[0...2], UNKNOWN, *p[2..-1], &e
			end
		ensure db.close
		end
	end

	class Btree < DB
		def self.new *p, &e
			super *p[0...2], BTREE, *p[2..-1], &e
		end
	end

	class Hash < DB
		def self.new *p, &e
			super *p[0...2], HASH, *p[2..-1], &e
		end
	end

	class Recno < DB
		def self.new *p, &e
			super *p[0...2], RECNO, *p[2..-1], &e
		end

		def []( k)     super k.to_s  end
		def []=( k, v) super k.to_s  end
	end
	Array = Recno

	class Queue < DB
		def self.new *p, &e
			super *p[0...2], QUEUE, *p[2..-1], &e
		end

		def []( k)     super k.to_s  end 
		def []=( k, v) super k.to_s  end
	end
end
