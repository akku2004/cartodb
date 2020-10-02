require_relative 'aggregator'

module CartoDB
  module Stats
    class UserTables < Aggregator

      PREFIX = 'tables'.freeze

      def self.instance(config={})
        # INFO: We explicitly not want anything on the prefix other than PREFIX constant
        super(PREFIX, config, host_info = nil)
      end

      def update_tables_counter(count)
        if count == -1
          decrement('total')
        else
          increment('total')
        end
      rescue StandardError
      end

      def update_tables_counter_per_user(count, user)
        if count == -1
          decrement("users.#{user}")
        else
          increment("users.#{user}")
        end
      rescue StandardError
      end

      def update_tables_counter_per_host(count)
        if count == -1
          decrement("hosts.#{Socket.gethostname.gsub('.', '_')}")
        else
          increment("hosts.#{Socket.gethostname.gsub('.', '_')}")
        end
      rescue StandardError
      end

      def update_tables_counter_per_plan(count, plan)
        if count == -1
          decrement("plans.#{plan.gsub(/[\[\]]/, '').upcase}")
        else
          increment("plans.#{plan.gsub(/[\[\]]/, '').upcase}")
        end
      rescue StandardError
      end

    end
  end
end
