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
require_relative "error"
require_relative "payload"
require_relative "response"

module Deployer
  class App
    def initialize(base_dir)
      @base_dir = base_dir
      @log_dir = base_dir + "log"
      @log_dir.mkpath
    end

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
        payload = parse_body!(request)
        process_payload!(payload)
      rescue RequestError => request_error
        response.set(request_error.status, request_error.message)
      rescue => e
        response.set(:internal_server_error, e.message)
      end
    end

    def verify_signature!(request, body)
      hmac_sha256 = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"),
                                            ENV["SECRET_TOKEN"],
                                            body)
      signature = "sha256=#{hmac_sha256}"
      unless Rack::Utils.secure_compare(signature, request.env["HTTP_X_HUB_SIGNATURE_256"])
        raise RequestError.new(:unauthorized, "Authorization failed")
      end
    end

    def parse_body!(request)
      unless request.media_type == "application/json"
        raise RequestError.new(:bad_request, "invalid payload format")
      end

      body = request.body.read
      if body.nil?
        raise RequestError.new(:bad_request, "request body is missing")
      end

      verify_signature!(request, body)

      begin
        raw_payload = JSON.parse(body)
      rescue JSON::ParserError
        raise RequestError.new(:bad_request,
                               "invalid JSON format: #{$!.message}\n" +
                               body)
      end

      metadata = {
        "x-github-event" => request.env["HTTP_X_GITHUB_EVENT"]
      }
      Payload.new(raw_payload, metadata)
    end

    def process_payload!(payload)
      case payload.event_name
      when "ping"
        # Do nothing because this is a kind of healthcheck.
      when "release", "workflow_run"
        return unless payload.released?
        deploy(payload)
      else
        raise RequestError.new(:bad_request, "Unsupported event: <#{payload.event_name}>")
      end
    end

    def deploy(payload)
      env = {
        "BUNDLE_GEMFILE" => nil, # Enforce using ../Gemfile
        "GITHUB_OWNER" => payload.repository_owner,
        "GITHUB_REPOSITORY" => payload.repository_name,
        "VERSION" => payload.version,
        "TAG" => payload.tag_name,
      }
      case [env["GITHUB_OWNER"], env["GITHUB_REPOSITORY"]]
      when ["groonga", "groonga"]
        env["PACKAGE"] = "groonga"
      when ["groonga", "groonga-nginx"]
        env["PACKAGE"] = "groonga-nginx"
      when ["groonga", "groonga-normalizer-mysql"]
        env["PACKAGE"] = "groonga-normalizer-mysql"
      when ["mroonga", "mroonga"]
        env["PACKAGE"] = "mroonga"
      when ["pgroonga", "pgroonga"]
        env["PACKAGE"] = "pgroonga"
      else
        return
      end

      Thread.new do
        pid = spawn(env,
                    "bin/rake",
                    in: IO::NULL,
                    out: (@log_dir + "deploy.output.log").to_s,
                    err: (@log_dir + "deploy.error.log").to_s,
                    chdir: (@base_dir + "..").to_s)
        Process.waitpid(pid)
      end
    end
  end
end
