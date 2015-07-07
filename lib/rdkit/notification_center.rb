module RDKit
  class NotificationCenter
    module ClassMethods
      @@channels = {}
      @@channels.default = Hash.new

      def publish(channel, message)
        @@channels[channel.to_sym].each { |_, block| block.call(message) }
      end

      def subscribe(channel, client, &block)
        @@channels[channel.to_sym][client] = block
      end

      def unsubscribe(channel, client)
        @@channels[channel.to_sym].delete(client)
      end
    end
    class << self; include ClassMethods; end
  end
end
