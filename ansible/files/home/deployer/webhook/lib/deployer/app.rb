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
require_relative "source-archive"

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
        JSON.parse(payload)
      rescue JSON::ParserError
        response.set(:bad_request, "invalid JSON format: <#{$!.message}>")
        nil
      end
    end

    def process_payload(request, response, raw_payload)
      metadata = {
        "x-github-event" => request.env["HTTP_X_GITHUB_EVENT"]
      }

      payload = Payload.new(raw_payload, metadata)

      case payload.event_name
      when "ping"
        # Do nothing because this is a kind of healthcheck.
        nil
      when "workflow_run"
        return unless payload.released?
        process_release(request, response, payload)
      else
        response.set(:bad_request,
                     "Unsupported event: <#{payload.event_name}>")
        nil
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
