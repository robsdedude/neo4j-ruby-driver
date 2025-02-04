module Testkit
  module Backend
    class CommandProcessor
      delegate :delete, :fetch, to: :@objects

      def initialize(socket)
        @socket = socket
        @buffer = String.new
        @objects = Hash.new
      end

      def process(blocking: false)
        var = (blocking ? @socket.gets : @socket.read_nonblock(4096))
        return unless var
        puts "#{blocking ? 'blocking:' : 'nonblocking:'} <#{var}>"
        @buffer << var
        if (request_begin = @buffer.match(/^#request begin$/)&.end(0)) &&
          (request_end_match = @buffer.match(/^#request end$/))
          to_process = (@buffer[request_begin..request_end_match.begin(0) - 1])#.tap {|var| puts "processing: <#{var}>"}
          @buffer = @buffer[request_end_match.end(0)..@buffer.size]
          process_request(to_process)
        else
          true
        end
      end

      def process_request(request)
        Messages::Request.from(JSON.parse(request, symbolize_names: true), self).tap do |message|
          process_response(message.process_request)
        end
      end

      def process_response(response_message)
        @socket.write(response(response_message))
      end

      def store(object)
        object.object_id.tap { |id| @objects[id] = object }
      end

      def to_testkit(name, object)
        { name: name.to_s, data: { id: object.object_id } }
      end

      def response(message)
        "#response begin\n#{JSON.dump(message)}\n#response end\n".tap {|var| puts "written: <#{var}>"} if message
      end
    end
  end
end
