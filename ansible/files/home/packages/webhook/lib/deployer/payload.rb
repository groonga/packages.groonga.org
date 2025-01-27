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
    RELEASE_WORKFLOWS = ["Package", "CMake"].freeze

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

    def workflow_name
      self["workflow_run.name"]
    end

    def workflow_succeeded?
      self["workflow_run.conclusion"] == "success"
    end

    def branch
      self["workflow_run.head_branch"]
    end

    def tag_name
      case event_name
      when "release"
        self["release.tag_name"]
      when "workflow_run"
        return nil unless workflow_tag?
        branch
      else
        nil
      end
    end

    def version
      case event_name
      when "release"
      when "workflow_run"
        return nil unless workflow_tag?
      else
        return nil
      end
      tag_name.delete_prefix("v")
    end

    def released?
      case event_name
      when "release"
        self["action"] == "published"
      when "workflow_run"
        RELEASE_WORKFLOWS.include?(workflow_name) &&
          workflow_tag? &&
          workflow_succeeded?
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

    private

    def workflow_tag?
      return false unless branch
      branch.match?(/\Av\d+(\.\d+){1,2}\z/)
    end
  end
end
