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
    RELEASE_WORKFLOWS= ["Package"].map(&:freeze).freeze

    def initialize(data, metadata={})
      @data = data
      @metadata = metadata
    end

    def [](key)
      key.split(".").inject(@data) do |current_data, current_key|
        if current_data
          current_data[current_key]
        else
          nil
        end
      end
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

    def version
      return nil unless workflow_tag?
      branch.delete_prefix("v")
    end

    def released?
      RELEASE_WORKFLOWS.include?(workflow_name) &&
      workflow_tag? &&
      workflow_succeeded?
    end

    def repository_owner
      owner = self["repository.owner"] || {}
      owner["login"]
    end

    def repository_name
      self["repository.name"]
    end

    private

    def workflow_tag?
      return if branch
      branch.match?(/^v\d+(\.\d+){2}$/)
    end
  end
end