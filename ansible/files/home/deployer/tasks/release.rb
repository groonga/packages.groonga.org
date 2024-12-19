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

Release = Struct.new(:github_owner,
                     :github_repository,
                     :package,
                     :version,
                     :tag,
                     :gpg_key_id) do
  def github_owner
    ENV["GITHUB_OWNER"] || self[:github_owner]
  end

  def github_repository
    ENV["GITHUB_REPOSITORY"] || self[:github_repository]
  end

  def package
    ENV["PACKAGE"] || self[:package]
  end

  def version
    ENV["VERSION"] || self[:version]
  end

  def tag
    ENV["TAG"] || self[:tag]
  end

  def gpg_key_id
    ENV["GPG_KEY_ID"] || self[:gpg_key_id]
  end
end
