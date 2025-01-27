# Copyright (C) 2024  Sutou Kouhei <kou@clear-code.com>
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

require "json"
require "open-uri"

class GitHubClient
  def initialize(owner, repository)
    @owner = owner
    @repository = repository
  end

  def release(tag)
    api_uri("releases/tags/#{tag}").open do |input|
      JSON.parse(input.read)
    end
  end

  def latest_release
    api_uri("releases/latest").open do |input|
      JSON.parse(input.read)
    end
  end

  def latest_released_tag?(tag)
    latest_release["tag_name"] == tag
  end

  private
  def api_uri(path)
    URI("https://api.github.com/repos/#{@owner}/#{@repository}/#{path}")
  end
end
