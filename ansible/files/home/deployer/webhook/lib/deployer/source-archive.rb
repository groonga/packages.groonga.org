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

module Deployer
  # Usage:
  #
  #   github_owner = "groonga"
  #   github_repository = "groonga"
  #   package = "groonga"
  #   version = "14.1.1"
  #   tag = "v14.1.1"
  #   gpg_key_id = "2701F317CFCCCB975CADE9C2624CF77434839225"
  #   archive = Deployer::SourceArchive.new(github_owner,
  #                                         github_repository,
  #                                         package,
  #                                         version,
  #                                         tag,
  #                                         gpg_key_id)
  #   archive.process
  class SourceArchive
    def initialize(github_owner, github_repository, package, version, tag)
      @github_owner = github_owner
      @github_repository = github_repository
      @package = package
      @version = version
      @tag = tag
      @github_client = GitHubClient.new(@github_owner, @github_repository)
    end

    def process(gpg_key_id)
      Dir.mktmpdir do |dir|
        download(dir)
        sign(dir, gpg_key_id)
        upload(dir)
      end
    end

    private
    def download(dir)
      @github_client.release(@tag)["assets"].each do |asset|
        file_name = asset["name"]
        case file_name
        when "#{@package}-#{@version}.tar.gz", "#{@package}-#{@version}.zip"
          File.open(File.join(dir, file_name), "wb") do |output|
            URI(asset["browser_download_url"]).open do |input|
              IO.copy_stream(input, output)
            end
          end
        end
      end
    end

    def sign(dir, gpg_key_id)
      Dir.glob("*", base: dir) do |relative_path|
        path = File.join(dir, relative_path)
        run_command("gpg",
                    "--armor",
                    "--detach-sign",
                    "--local-user", gpg_key_id,
                    path)
      end
    end

    def upload(dir)
      paths = Dir.glob("*.asc", base: dir).collect do |relative_path|
        File.join(dir, relative_path)
      end
      run_command("gh",
                  "release",
                  "upload",
                  @tag,
                  "--clobber",
                  "--repo", "#{@github_owner}/#{@github_repository}",
                  *paths)
    end

    def run_command(*command_line)
      unless system(*command_line)
        raise "failed to run: #{command_line.join(" ")}"
      end
    end
  end
end

