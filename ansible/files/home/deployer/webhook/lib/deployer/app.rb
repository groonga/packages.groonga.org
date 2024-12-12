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

require "json"
require "openssl"
require_relative "response"

module Deployer
  class App
    def call(env)
      request = Rack::Request.new(env)
      response = Response.new
      process(request, response) || response.finish
    end

    private

    def process(request, response)
      unless request.post?
        response.set(:method_not_allowed, "must POST")
        return
      end

      unless valid_signature?(request)
        response.set(:unauthorized, "Authorization failed")
        return
      end

      payload = parse_payload(request, response)
      return if payload.nil?
      process_payload(request, response, payload)
    end

    def valid_signature?(request)
      hmac_sha256 = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"),
                                            ENV["SECRET_TOKEN"],
                                            request.body.read)
      signature = "sha256=#{hmac_sha256}"
      Rack::Utils.secure_compare(signature, request.env["HTTP_X_HUB_SIGNATURE_256"])
    end

    def parse_payload(request, response)
      unless request.media_type == "application/json"
        response.set(:bad_request, "invalid payload format")
        return
      end

      payload = request.body.read
      if payload.nil?
        response.set(:bad_request, "payload is missing")
        return
      end

      begin
        JSON.parse(request.body.read)
      rescue JSON::ParserError
        response.set(:bad_request, "invalid JSON format: <#{$!.message}>")
        nil
      end
    end

    def process_payload(request, response, payload)
      event_action = payload["action"] # TODO we should decide which action trigger this webhook
      if event_action == "expected"
        # run rake task
      else
        response.set(:bad_request, "Unsupported event: <#{}>")
        nil
      end
    end
  end
end
