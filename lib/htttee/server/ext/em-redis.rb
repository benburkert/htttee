module EventMachine
  module Protocols
    module Redis

      def pipeline(*commands, &blk)
        command = ''

        commands.each do |argv|
          command << "*#{argv.size}\r\n"
          argv.each do |a|
            a = a.to_s
            command << "$#{get_size(a)}\r\n"
            command << a
            command << "\r\n"
          end
        end

        maybe_lock do
          commands.map {|c| c.first }.each do |command_name|
            @redis_callbacks << [REPLY_PROCESSOR[command_name], blk]
          end
          send_data command
        end
      end

      def multi(*command_groups, &blk)

        command = "*1\r\n$5\r\nMULTI\r\n"

        command_groups.each do |argv|
          command << "*#{argv.size}\r\n"
          argv.each do |a|
            a = a.to_s
            command << "$#{get_size(a)}\r\n"
            command << a
            command << "\r\n"
          end
        end

        command << "*1\r\n$4\r\nEXEC\r\n"

        maybe_lock do
          @redis_callbacks << [REPLY_PROCESSOR['multi'], blk]
          send_data command
        end
      end
    end
  end
end
