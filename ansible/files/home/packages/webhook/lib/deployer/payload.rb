# Copyright (C) 2010-2019  Sutou Kouhei <kou@clear-code.com>
# Copyright (C) 2015  Kenji Okimoto <okimoto@clear-code.com>
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

module Deployer
  class Payload
    def initialize(data, metadata={})
      @data = data
      @metadata = metadata
    end

    def [](key)
      @data.dig(*key.split("."))
    end

    def event_name
      @metadata["x-github-event"]
    end

    def tag_name
      case event_name
      when "release"
        self["release.tag_name"]
      else
        nil
      end
    end

    def version
      case event_name
      when "release"
        tag_name.delete_prefix("v")
      else
        nil
      end
    end

    def released?
      case event_name
      when "release"
        self["action"] == "published"
      else
        false
      end
    end

    def repository_owner
      self["repository.owner.login"]
    end

    def repository_name
      self["repository.name"]
    end
  end
end
