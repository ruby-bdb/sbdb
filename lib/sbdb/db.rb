require 'bdb'
require 'sbdb/cursor'

module SBDB
	TYPES = []
	class DB
		UNKNOWN = Bdb::Db::UNKNOWN
		BTREE = Bdb::Db::BTREE
		HASH = Bdb::Db::HASH
		QUEUE = Bdb::Db::QUEUE
		ARRAY = RECNO = Bdb::Db::RECNO
		RDONLY = READLONY = Bdb::DB_RDONLY
		CONSUME = Bdb::DB_CONSUME
		CONSUME_WAIT = Bdb::DB_CONSUME_WAIT

		attr_reader :home
		attr_accessor :txn
		include Enumerable
		def bdb_object()  @db  end
		def sync()  @db.sync  end
		def close( f = nil)  @db.close f || 0  end
		def cursor( &e)  Cursor.new self, &e  end

		def at k, txn = nil
			@db.get _txn(txn), k.nil? ? nil : k.to_s, nil, 0
		rescue Bdb::KeyEmpty
			return nil
		end
		alias [] at

		def put k, v, txn = nil
			if v.nil?
				@db.del _txn(txn), k.to_s, 0
			else
				@db.put _txn(txn), k.nil? ? nil : k.to_s, v.to_s, 0
			end
		end
		
		def []= k, v
			put k, v
		end

		def delete k, txn = nil
			@db.del _txn(txn), k.to_s
		end
		alias del delete

		class << self
			def new *ps, &exe
				ret = obj = super( *ps)
				begin ret = e.call obj
				ensure
					SBDB::raise_barrier obj.method(:sync)
					SBDB::raise_barrier obj.method(:close)
				end  if exe
				ret
			end
			alias open new
		end

		def _txn t
			t ||= @txn
			t && t.bdb_object
		end

		def initialize file, *args
			opts = ::Hash === args.last ? args.pop : {}
			opts = {:name => args[0], :type => args[1], :flags => args[2], :mode => args[3], :env => args[4]}.update opts
			#type = BTREE  if type == UNKNOWN and (flags & CREATE) == CREATE
			@home, @db = opts[:env], opts[:env] ? opts[:env].bdb_object.db : Bdb::Db.new
			opts[:type] = TYPES.index(self.class) || UNKNOWN
			@db.re_len = opts[:re_len]  if opts[:re_len]
			txn = opts[:txn]
			begin
				@db.open txn && txn.bdb_object, file, opts[:name], opts[:type], opts[:flags] || 0, opts[:mode] || 0
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

		def truncate txn = nil
			@db.truncate _txn(txn)
		end
	end

	class Unknown < DB
		def self.new file, *p, &e
			dbt = super( file, *p) {|db| db.bdb_object.get_type }
			TYPES[dbt] ? TYPES[dbt].new( file, *p, &e) : super( file, *p, &e)
		end
	end

	class Btree < DB
	end
	TYPES[DB::BTREE] = Btree

	class Hash < DB
	end
	TYPES[DB::HASH] = Hash

	module Arrayisch
		def [] k
			super [k].pack('I')
		end

		def []= k, v
			super [k].pack('I'), v
		end

		def push v, txn = nil
			@db.put _txn(txn), "\0\0\0\0", v, Bdb::DB_APPEND
		end
	end

	class Recno < DB
		extend Arrayisch
	end
	Array = Recno
	TYPES[DB::RECNO] = Recno

	class Queue < Arrayisch
		extend Arrayisch
		def unshift txn = nil
			@db.get _txn(txn), "\0\0\0\0", nil, Bdb::DB_CONSUME
		end
	end
	TYPES[DB::QUEUE] = Queue
end
