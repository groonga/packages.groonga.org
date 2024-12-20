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

require "tmpdir"

require_relative "github-client"
require_relative "release"

class SourceArchiveTask
  include Rake::DSL

  def initialize(release)
    @release = release
    @github_client = GitHubClient.new(@release.github_owner,
                                      @release.github_repository)
  end

  def define
    namespace :deploy do
      desc "Deploy source archive"
      task :source_archive do
        Dir.mktmpdir do |dir|
          download(dir)
          sign(dir)
          upload(dir)
        end
      end
    end
  end

  private
  def download(dir)
    base_name = "#{@package}-#{@version}"
    @github_client.release(@release.tag)["assets"].each do |asset|
      file_name = asset["name"]
      case file_name
      when "#{base_name}.tar.gz", "#{base_name}.zip"
        File.open(File.join(dir, file_name), "wb") do |output|
          URI(asset["browser_download_url"]).open do |input|
            IO.copy_stream(input, output)
          end
        end
      end
    end
  end

  def sign(dir)
    Dir.glob("*", base: dir) do |relative_path|
      path = File.join(dir, relative_path)
      sh("gpg",
         "--armor",
         "--detach-sign",
         "--local-user", @release.gpg_key_id,
         path)
    end
  end

  def upload(dir)
    paths = Dir.glob("*.asc", base: dir).collect do |relative_path|
      File.join(dir, relative_path)
    end
    repository = "#{@release.github_owner}/#{@release.github_repository}"
    sh("gh",
       "release",
       "upload",
       @release.tag,
       "--clobber",
       "--repo", repository,
       *paths)
  end
end
