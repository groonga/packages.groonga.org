# Copyright (C) 2018  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2024  Takuya Kodama <otegami@clear-code.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

require "pathname"

module Deployer
  class Logger
    LOG_DIR = "log".freeze

    class << self
      def log(base_name, object)
        new(base_name).log(object)
      end
    end

    def initialize(base_name)
      @log_dir = prepare_log_dir
      @base_name = base_name
      @log_path = log_dir + base_name
    end

    def log(object)
      begin
        File.open(@log_path, "w") do |log|
          if object.is_a?(String)
            log.puts(object)
          else
            PP.pp(object, log)
          end
        end
      rescue SystemCallError
      end
    end

    private

    def prepare_log_dir
      log_dir = Pathname.new(LOG_DIR)
      return log_dir if log_dir.directory?

      Pathname.mkdir(LOG_DIR)
      log_dir
    end
  end
end
