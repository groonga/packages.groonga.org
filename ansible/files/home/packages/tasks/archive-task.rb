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
require_relative "state"

class ArchiveTask
  include Rake::DSL

  def initialize(release)
    @release = release
    @github_client = GitHubClient.new(@release.github_owner,
                                      @release.github_repository)
  end

  def define
    namespace :deploy do
      desc "Deploy archives"
      task :archives do
        return unless @github_client.latest_released?(@release.tag)

        target_assets.each do |type, asset|
          base_name = asset["name"]
          if type == "source"
            # groonga-14.1.1.tar.gz -> tar.gz
            # groonga-14.1.1.zip    -> zip
            extension = base_name.delete_prefix("#{@release.base_name}.")
            state_id = "source-#{extension}"
          else
            # groonga-14.1.1-x64-vs2019-with-vcruntime.zip ->
            # x64-vs2019-with-vcruntime
            #
            # groonga-14.1.1-x64-vs2022.zip ->
            # x64-vs2022
            binary_type = base_name.
                            delete_prefix("#{@release.base_name}-").
                            delete_suffix(".zip")
            state_id = "windows-#{binary_type}"
          end
          state = State.new(@release.base_dir,
                            @release.package,
                            @release.version,
                            state_id)
          next if state.done?

          state.lock do
            Dir.mktmpdir do |dir|
              download(dir, asset)
              sign(dir)
              upload(dir)
            end

            update_htaccess(type, asset)
            state.done
          end
        end
      end
    end
  end

  private
  def target_assets
    source_archive_assets = {}
    windows_binary_assets = {}
    sign_file_names = []
    @github_client.release(@release.tag)["assets"].each do |asset|
      file_name = asset["name"]
      case file_name
      when "#{@release.base_name}.tar.gz", "#{@release.base_name}.zip"
        source_archive_assets[file_name] = asset
      when /\A#{Regexp.escape(@release.base_name)}-.+\.zip\z/
        windows_binary_assets[file_name] = asset
      when /\.asc\z/
        sign_file_names << file_name
      end
    end
    sign_file_names.each do |sign_file_name|
      signed_file_name = sign_file_name.gsub(/\.asc\z/, "")
      source_archive_assets.delete(signed_file_name)
      windows_binary_assets.delete(signed_file_name)
    end
    assets = []
    source_archive_assets.values.each do |asset|
      assets << ["source", asset]
    end
    windows_binary_assets.values.each do |asset|
      assets << ["windows", asset]
    end
    assets
  end

  def download(dir, asset)
    file_name = asset["name"]
    File.open(File.join(dir, file_name), "wb") do |output|
      URI(asset["browser_download_url"]).open do |input|
        IO.copy_stream(input, output)
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

  def update_htaccess(type, asset)
    htaccess_path = @release.public_dir + type + @release.package + ".htaccess"
    return unless htaccess_path.exist?

    base_name = asset["name"]
    latest_base_name = base_name.gsub(/\A#{Regexp.escape(@release.base_name)}/) do
      "#{@release.package}-latest"
    end
    htaccess_content = ""
    htaccess_path.open do |htaccess|
      htaccess.each_line do |line|
        htaccess_content << line unless line.include?(latest_base_name)
      end
      url = asset["browser_download_url"]
      [
        base_name,
        latest_base_name,
      ].each do |target_base_name|
        target = "/#{type}/#{@release.package}/#{target_base_name}"
        htaccess_content << "Redirect #{target} #{url}\n"
        htaccess_content << "Redirect #{target}.asc #{url}.asc\n"
      end
    end
    htaccess_path.write(htaccess_content)
  end
end
