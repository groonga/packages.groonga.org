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

require_relative "lib/deployer"

dot_env_path = File.join(__dir__, ".env")
if File.exist?(dot_env_path)
  File.open(dot_env_path) do |dot_env|
    dot_env.each_line(chomp: true) do |line|
      line.strip!
      next if line.empty?
      next if line.start_with?("#")
      key, value = line.split("=", 2)
      next if value.nil?
      ENV[key] = value
    end
  end
end

run Deployer::App.new
