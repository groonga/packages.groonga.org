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
require_relative "payload"
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

      begin
        payload = parse_body(request, response)
        process_payload(request, response, payload)
      rescue => e
        response.set(:bad_request, e.message)
        return
      end
    end

    def valid_signature?(request)
      hmac_sha256 = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"),
                                            ENV["SECRET_TOKEN"],
                                            request.body.read)
      signature = "sha256=#{hmac_sha256}"
      Rack::Utils.secure_compare(signature, request.env["HTTP_X_HUB_SIGNATURE_256"])
    end

    def parse_body(request, response)
      unless request.media_type == "application/json"
        raise "invalid payload format"
      end

      body = request.body.read
      if body.nil?
        raise "request body is missing"
      end

      begin
        raw_payload = JSON.parse(body)
      rescue JSON::ParserError
        raise "invalid JSON format: <#{$!.message}>"
      end
      metadata = {
        "x-github-event" => request.env["HTTP_X_GITHUB_EVENT"]
      }
      Payload.new(raw_payload, metadata)
    end

    def process_payload(request, response, payload)
      case payload.event_name
      when "ping"
        # Do nothing because this is a kind of healthcheck.
        nil
      when "workflow_run"
        return unless payload.released?
        process_release(request, response, payload)
      else
        raise "Unsupported event: <#{payload.event_name}>"
      end
    end

    def process_release(request, response, payload)
      response.finish do
        Thread.new do
          # TODO: call rake tasks for sign packages.
        end
      end
    end
  end
end
