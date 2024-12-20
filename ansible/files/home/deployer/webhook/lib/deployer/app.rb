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
      process(request, response)
      response.finish
    end

    private

    def process(request, response)
      begin
        unless request.post?
          raise RequestError.new(:method_not_allowed, "must POST")
        end
        verify_signature!(request)
        payload = parse_body(request)
        process_payload(payload, response)
      rescue => e
        response.set(:bad_request, e.message)
      end
    end

    def verify_signature!(request)
      hmac_sha256 = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"),
                                            ENV["SECRET_TOKEN"],
                                            request.body.read)
      signature = "sha256=#{hmac_sha256}"
      unless Rack::Utils.secure_compare(signature, request.env["HTTP_X_HUB_SIGNATURE_256"])
        raise RequestError.new(:unauthorized, "Authorization failed")
      end
    end

    def parse_body(request)
      unless request.media_type == "application/json"
        raise RequestError.new(:bad_request, "invalid payload format")
      end

      body = request.body.read
      if body.nil?
        raise RequestError.new(:bad_request, "request body is missing")
      end

      begin
        raw_payload = JSON.parse(body)
      rescue JSON::ParserError
        raise RequestError.new(:bad_request, "invalid JSON format: <#{$!.message}>")
      end

      metadata = {
        "x-github-event" => request.env["HTTP_X_GITHUB_EVENT"]
      }
      Payload.new(raw_payload, metadata)
    end

    def process_payload(payload, response)
      case payload.event_name
      when "ping"
        # Do nothing because this is a kind of healthcheck.
        nil
      when "workflow_run"
        return unless payload.released?
        deploy(payload, response)
      else
        raise RequestError.new(:bad_request, "Unsupported event: <#{payload.event_name}>")
      end
    end

    def deploy(payload, response)
      release_tasks = Proc.new do
        # TODO: call rake tasks for sign packages.
      end
      response.set_finish_proc(release_tasks)
    end
  end
end
