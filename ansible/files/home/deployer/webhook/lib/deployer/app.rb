# Copyright (C) 2024  Horimoto Yasuhiro <horimoto@clear-code.com>
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

require "openssl"
require_relative "response"

module Deployer
  class App
    def call(env)
      request = Rack::Request.new(env)
      response = Response.new
      process(request, response)
      response.finish
    end

    private

    def process(request, response)
      unless request.post?
        response.set(:method_not_allowed, "must POST")
        return nil
      end

      unless verify_signature(request)
        response.set(:unauthorized, "Authorization failed")
        return nil
      end
    end

    def verify_signature(request)
      signature = "sha256=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"),
                                                      ENV["SECRET_TOKEN"],
                                                      request.body.read)
      Rack::Utils.secure_compare(signature, request.env["HTTP_X_HUB_SIGNATURE_256"])
    end
  end
end
