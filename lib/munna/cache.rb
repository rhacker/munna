require 'singleton'

module Munna
	class Cache
		include Singleton

		def initalize
			values
		end

		def values
			Rails.cache.fetch(Munna::KEY) { Hash.new }
		end

		def clear
			values.keys.each {|k| Rails.cache.delete k }
			Rails.cache.delete(Munna::KEY)
		end

		def method_missing(name, *args, &block)
			if /^write$|^delete$/ =~ name.to_s
				CacheHelper.handle_key(name, args.first)
			elsif /(?<type>.+)_matched$/ =~ name.to_s
				CacheHelper.handle_matched(type, args.first)
			else
				super(name, *args, &block)
			end
		end
	end

	module CacheHelper
		class << self
			def handle_matched(action, regex)
				matches = Munna.cache.values.select {|v| regex =~ v}
				send("#{action}_matched", matches)
			end

			def delete_matched(matches)
				matches.each {|m| Munna.cache.delete(m)}
			end

			def get_matched(matches)
				matches
			end

			def handle_key(action, key)
				Rails.cache.write(Munna::KEY, send("#{action}_key", Munna.cache.values, key))
			end

			def write_key(values, key)
				values[key] = values[key].to_i + 1 and values
			end

			def delete_key(values, key)
				values.reject do |v|
					if normailize_value(v) == normailize_value(key)
						Rails.cache.delete(v) and true
					end
				end
			end

			def normailize_value(key)
				key.gsub /-[^\/]+/, ''
			end
		end
	end
end
