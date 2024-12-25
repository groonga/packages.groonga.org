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

class State
  def initialize(base_dir, package, version, id)
    @state_dir = base_dir + "state" + package + version + id
    @state_dir.mkpath
    @done_path = @state_dir + "done"
    @lock_path = @state_dir + "lock"
  end

  def done?
    @done_path.exist?
  end

  def done
    @done_path.open("w") do
      # Just create
    end
  end

  def lock
    lock_path = @state_dir + "lock"
    begin
      lock_path.open(File::CREAT | File::EXCL | File::WRONLY) do
        yield
      end
    ensure
      begin
        lock_path.unlink
      rescue SystemCallError
      end
    end
  end
end
