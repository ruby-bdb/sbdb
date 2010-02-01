
module SBDB
	class Cursor
		NEXT  = Bdb::DB_NEXT
		FIRST = Bdb::DB_FIRST
		LAST  = Bdb::DB_LAST
		PREV  = Bdb::DB_PREV
		SET   = Bdb::DB_SET

		attr_reader :db

		include Enumerable
		def bdb_object()  @cursor  end
		def close()  @cursor.close  end
		def get( k, v, f)  @cursor.get k, v, f  end
		def count()  @cursor.count  end
		def first( k = nil, v = nil)  @cursor.get k, v, FIRST  end
		def last(  k = nil, v = nil)  @cursor.get k, v, LAST   end 
		def next(  k = nil, v = nil)  @cursor.get k, v, NEXT   end 
		def prev(  k = nil, v = nil)  @cursor.get k, v, PREV   end

		def self.new *p
			x = super *p
			return x  unless block_given?
			begin yield x
			ensure x.close
			end
		end

		def initialize ref
			@cursor, @db = *case ref
				when Cursor  then [ref.bdb_object.dup, ref.db]
				when Bd::Db::Cursor  then [ref]
				else [ref.bdb_object.cursor( nil, 0), ref]
				end
		end

		def reverse k = nil, v = nil, &e
			each k, v, LAST, PREV, &e
		end

		def each k = nil, v = nil, f = nil, n = nil
			return Enumerator.new( self, :each, k, v, f, n)  unless block_given?
			n ||= NEXT
			e = @cursor.get k, v, f || FIRST
			return  unless e
			yield *e
			yield *e  while e = @cursor.get( k, v, n)
			nil
		end
	end
end
