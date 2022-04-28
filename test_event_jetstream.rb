require "fluent/plugin/input"
require 'nats/client'

module Fluent
  module Plugin
    class JetstreamInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("jetstream", self)

      helpers :thread

      config_param :server, :string, :default => 'localhost:4222',
                   :desc => "NATS streaming server host:port"
      config_param :interval, :integer, :default => 1, # seconds
                   :desc => "Interval (Unit: seconds)"
      config_param :consumer, :string, :default => nil,
                   :desc => "consumer name"
      config_param :subject, :string, :default => nil,
                   :desc => "subject name"
      config_param :start_at, :string, :default => "deliver_all_available",
                   :desc => "start at"

      config_param :fetch_size, :integer, :default => 1,
                   :desc => "The number of request pull fetch size"
      config_param :max_reconnect_attempts, :integer, :default => 10,
                   :desc => "The max number of reconnect tries"
      config_param :reconnect_time_wait, :integer, :default => 5,
                   :desc => "The number of seconds to wait between reconnect tries"
      config_param :max_consume_interval, :integer, :default => 120,
                   :desc => "max consume interval time"

      config_param :tag, :string, :default => 'fluentd',
                   :desc => "tag"

      def configure(conf)
        super

        servers = [ ]
        @server.split(',').map do |server_str|
          server_str = server_str.strip
          servers.push("nats://#{server_str}")
        end

        @cluster_opts = {
          servers: servers,
          reconnect_time_wait: @reconnect_time_wait,
          max_reconnect_attempts: @max_reconnect_attempts
        }
      end

      def start
        super
        # @running = true
        @loop = Coolio::Loop.new

        @nc = NATS.connect(@cluster_opts)
        @js = @nc.jetstream()
        @psub = @js.pull_subscribe(@subject, @consumer)

        @nc.on_error do |e|
          log.error "nats Error: #{e}"
        end

        @nc.on_reconnect do
          log.info "nats Reconnected to server at #{@nc.connected_server}"
        end

        @nc.on_disconnect do
          log.info "nats Disconnected!"
        end

        @nc.on_close do
          log.info "Connection to nats closed"
        end

        tw = TopicWatcher.new(router, @tag, @psub, @fetch_size, @interval)
        tw.attach(@loop)

        @thread = Thread.new(&method(:run))
        log.info "listening nats on #{@cluster_opts[:servers]}/#{@subject}/#{@consumer}/#{@fetch_size}"
      end

      def shutdown
        # @running = false
        @loop.stop
        @thread.join

        @nc.flush
        @nc.drain if @nc
        @nc.close if @nc
        super
      end

      def run
        @loop.run
      rescue => e
        $log.error "unexpected error", :error => e.to_s
        $log.error_backtrace
      end

    end

    class TopicWatcher < Coolio::TimerWatcher
      def initialize(router, tag, psub, fetch_size, interval)
        @psub = psub
        @fetch_size = fetch_size
        @tag = tag
        @router = router

        @cb = method(:consume)

        super(interval, true)
      end

      def on_timer
        @cb.call
      rescue => e
        # TODO log?
        $log.error e.to_s
        $log.error_backtrace
      end

      def consume
        begin
          @psub.fetch(@fetch_size).each do |msg|
            tag = "#{@tag}"
            begin
              message = JSON.parse(msg.data)
            rescue  JSON::ParserError => e
              $log.error "Failed parsing JSON #{e.inspect}.  Passing as a normal string"
              message = msg
            end
            msg.ack
            time = Engine.now
            @router.emit(tag, time, message || {})
          end
        rescue NATS::Timeout => e
          $log.debug "nats: request timed out: #{e}"
          #retry
        rescue => e
          $log.error "loop Error: #{e}"
        end
      end

    end

  end
end