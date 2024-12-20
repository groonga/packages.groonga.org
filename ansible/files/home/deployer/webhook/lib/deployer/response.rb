# Copyright (C) 2010-2019  Sutou Kouhei <kou@clear-code.com>
# Copyright (C) 2015  Kenji Okimoto <okimoto@clear-code.com>
# Copyright (C) 2024  Horimoto Yasuhiro <horimoto@clear-code.com>
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

require "rack/response"

module Deployer
  class Response < Rack::Response
    def set(status_keyword, message)
      self.status = Rack::Utils.status_code(status_keyword)
      self["Content-Type"] = "text/plain"
      write(message)
    end

    def set_finish_proc(proc)
      @proc = proc
    end

    def finish
      super(&@proc)
    end
  end
end
