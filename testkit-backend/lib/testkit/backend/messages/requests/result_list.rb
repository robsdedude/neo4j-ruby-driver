module Testkit::Backend::Messages
  module Requests
    class ResultList < Request
      def process
        result = fetch(resultId)
        named_entity('RecordList', records: result.map { |record| { values: record.values.map(&method(:to_testkit)) } })
      end
    end
  end
end
