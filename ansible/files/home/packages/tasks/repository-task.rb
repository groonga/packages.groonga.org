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

# This is borrowed from
# https://github.com/red-data-tools/packages.red-data-tools.org/blob/main/repository-task.rb
# .

require "pathname"
require "tempfile"
require "thread"

require "apt-dists-merge"

require_relative "release"

class RepositoryTask
  include Rake::DSL

  class ThreadPool
    def initialize(n_workers, &worker)
      @n_workers = n_workers
      @worker = worker
      @jobs = Thread::Queue.new
      @workers = @n_workers.times.collect do
        Thread.new do
          loop do
            job = @jobs.pop
            break if job.nil?
            @worker.call(job)
          end
        end
      end
    end

    def <<(job)
      @jobs << job
    end

    def join
      @n_workers.times do
        @jobs << nil
      end
      @workers.each(&:join)
    end
  end

  class PackagesDir
    attr_reader :path
    def initialize(path)
      # .../packages/
      @path = Pathname(path)
    end

    def repository_type
      # .../packages/apt -> apt
      # .../packages/yum -> yum
      @path.glob("*")[0].basename.to_s
    end

    def distribution_path
      # .../packages/apt/repositories/debian
      # .../packages/yum/repositories/almalinux
      @path.glob("*/repositories/*")[0]
    end

    def distribution
      # .../packages/apt/repositories/debian    -> debian
      # .../packages/yum/repositories/almalinux -> almalinux
      distribution_path.basename.to_s
    end

    def version_path
      # .../packages/apt/repositories/debian/pool/bookworm
      # .../packages/yum/repositories/almalinux/9
      if repository_type == "apt"
        @path.glob("*/repositories/*/*/*")[0]
      else
        @path.glob("*/repositories/*/*")[0]
      end
    end

    def version
      # .../packages/apt/repositories/debian/pool/bookworm -> bookworm
      # .../packages/yum/repositories/almalinux/9          -> 9
      version_path.basename.to_s
    end

    # This is only for repository_type == "apt"
    def component_path
      # .../packages/apt/repositories/debian/pool/bookworm/main
      version_path.glob("*")[0]
    end

    # This is only for repository_type == "apt"
    def component
      # .../packages/apt/repositories/debian/pool/bookworm/main -> main
      component_path.basename.to_s
    end
  end

  class State
    def initialize(base_dir, id)
      @state_dir = base_dir + "state" + id
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

  def initialize(release, base_dir)
    @release = release
    @base_dir = Pathname(base_dir).expand_path
    @github_client = GitHubClient.new(@release.github_owner,
                                      @release.github_repository)
  end

  def define
    namespace :deploy do
      desc "Deploy repositories"
      task :repositories do
        target_assets.each do |target, assets|
          state = State.new(@base_dir, target)
          next if state.done?

          state.lock do
            Dir.mktmpdir do |dir|
              assets.each do |asset|
                url = asset["browser_download_url"]
                packages_tar_gz = File.join(dir, File.basename(url))
                File.open(packages_tar_gz, "wb") do |output|
                  URI(url).open do |input|
                    IO.copy_stream(input, output)
                  end
                end
                sh("tar", "xf", packages_tar_gz, "-C", dir)
              end

              packages_dir = PackagesDir.new(File.join(dir, "packages"))
              if packages_dir.repository_type == "yum"
                sign_rpms(packages_dir)
                update_yum_repository(packages_dir)
              else
                sign_dscs(packages_dir)
                update_apt_repository(packages_dir)
              end
            end
            state.done
          end
        end
      end
    end
  end

  private
  # This must be synced with /helper.rb
  def repository_label
    "The Groonga Project"
  end

  # This must be synced with /helper.rb
  def repository_description
    "Groonga related packages"
  end


  def target_assets
    package_assets = {}
    repository_assets = {}
    @github_client.release(@release.tag)["assets"].each do |asset|
      file_name = asset["name"]
      case file_name
      when /\Aalmalinux-/, /\Aamazon-linux-/, /\Adebian-/, /\Aubuntu-/
        if file_name.end_with?("-repository.tar.gz")
          repository_assets[file_name] = asset
        else
          package_assets[file_name] = asset
        end
      end
    end
    package_assets.reject! do |file_name, _asset|
      repository_assets.key?(file_name.gsub(/\.tar\.gz\z/, "-repository.tar.gz"))
    end
    grouped_package_assets = {}
    package_assets.each do |file_name, asset|
      # almalinux-8-aarch64.tar.gz -> almalinux-8
      # almalinux-8-x86_64.tar.gz  -> almalinux-8
      #
      # debian-bookworm-amd64.tar.gz -> debian-bookworm
      # debian-bookworm-arm64.tar.gz -> debian-bookworm
      group_key = file_name.gsub(/-(?:aarch64|x86_64|arm64|amd64)\.tar\.gz\z/, "")
      grouped_package_assets[group_key] ||= []
      grouped_package_assets[group_key] << asset
    end
    grouped_package_assets
  end

  def sign_rpms(dir)
    thread_pool = ThreadPool.new(4) do |rpm|
      sh("rpm",
         "-D", "_gpg_name #{@release.gpg_key_id}",
         "-D", "__gpg_check_password_cmd /bin/true true",
         "--resign",
         rpm)
    end
    Dir.glob("#{dir.path}/**/*.rpm") do |rpm|
      thread_pool << rpm
    end
    thread_pool.join
  end

  def update_yum_repository(dir)
    base_version_dir = @base_dir + "public" + dir.distribution + dir.version
    dir.version_path.glob("*") do |arch_dir|
      next unless arch_dir.directory?

      base_arch_dir = base_version_dir + arch_dir.basename
      rm_rf("#{arch_dir}/repodata")
      sh("rsync",
         "-av",
         arch_dir.to_s,
         base_version_dir.to_s)

      base_repodata_dir = "#{base_arch_dir}/repodata"
      if File.exist?(base_repodata_dir)
        cp_r(base_repodata_dir,
             arch_dir,
             preserve: true)
      end
      Tempfile.create("createrepo-c-packages") do |packages|
        arch_dir.glob("*/*.rpm") do |rpm|
          relative_rpm = rpm.relative_path_from(arch_dir)
          packages.puts(relative_rpm.to_s)
        end
        packages.close
        sh("createrepo_c",
           "--pkglist", packages.path,
           "--recycle-pkglist",
           "--retain-old-md-by-age=0",
           "--skip-stat",
           "--update",
           arch_dir.to_s)
      end
      sh("rsync",
         "-av",
         "--delete",
         "#{arch_dir}/repodata",
         (base_version_dir + arch_dir.basename).to_s)
    end
  end

  def sign_dscs(dir)
    Dir.glob("#{dir.path}/**/*.dsc") do |dsc|
      sh("debsign",
         "--no-re-sign",
         "-k#{@release.gpg_key_id}",
         dsc)
    end
  end

  def apt_architectures
    [
      "amd64",
      "arm64",
      "i386", # TODO: Remove me. We need to update apt-dists-merge for it.
    ]
  end


  def generate_apt_release(dists_dir, code_name, component, architecture)
    dir = "#{dists_dir}/#{component}/"
    if architecture == "source"
      dir << architecture
    else
      dir << "binary-#{architecture}"
    end

    mkdir_p(dir)
    File.open("#{dir}/Release", "w") do |release|
      release.puts(<<-RELEASE)
Archive: #{code_name}
Component: #{component}
Origin: #{repository_label}
Label: #{repository_label}
Architecture: #{architecture}
      RELEASE
    end
  end

  def generate_apt_ftp_archive_generate_conf(code_name, component)
    conf = <<-CONF
Dir::ArchiveDir ".";
Dir::CacheDir ".";
TreeDefault::Directory "pool/#{code_name}/#{component}";
TreeDefault::SrcDirectory "pool/#{code_name}/#{component}";
Default::Packages::Extensions ".deb .ddeb";
Default::Packages::Compress ". gzip xz";
Default::Sources::Compress ". gzip xz";
Default::Contents::Compress "gzip";
    CONF

    apt_architectures.each do |architecture|
      conf << <<-CONF

BinDirectory "dists/#{code_name}/#{component}/binary-#{architecture}" {
  Packages "dists/#{code_name}/#{component}/binary-#{architecture}/Packages";
  Contents "dists/#{code_name}/#{component}/Contents-#{architecture}";
  SrcPackages "dists/#{code_name}/#{component}/source/Sources";
};
      CONF
    end

    conf << <<-CONF

Tree "dists/#{code_name}" {
  Sections "#{component}";
  Architectures "#{apt_architectures.join(" ")} source";
};
    CONF

    conf
  end

  def generate_apt_ftp_archive_release_conf(code_name, component)
    <<-CONF
APT::FTPArchive::Release::Origin "#{repository_label}";
APT::FTPArchive::Release::Label "#{repository_label}";
APT::FTPArchive::Release::Architectures "#{apt_architectures.join(" ")}";
APT::FTPArchive::Release::Codename "#{code_name}";
APT::FTPArchive::Release::Suite "#{code_name}";
APT::FTPArchive::Release::Components "#{component}";
APT::FTPArchive::Release::Description "#{repository_description}";
    CONF
  end

  def update_apt_repository(dir)
    pool_dir = dir.version_path
    return unless pool_dir.exist?

    base_dir = dir.distribution_path
    distribution = dir.distribution
    code_name = dir.version
    component = dir.component

    current_distribution_dir = @base_dir + "public" + distribution

    sh("rsync",
       "-av",
       "--exclude=*.buildinfo",
       "--exclude=*.changes",
       pool_dir.to_s,
       (current_distribution_dir + "pool").to_s)

    dists_dir = base_dir + "dists" + code_name
    rm_rf(dists_dir.to_s)

    generate_apt_release(dists_dir, code_name, component, "source")
    apt_architectures.each do |architecture|
      generate_apt_release(dists_dir, code_name, component, architecture)
    end

    Tempfile.create("apt-ftparchive-generate.conf") do |generate_conf_file|
      conf = generate_apt_ftp_archive_generate_conf(code_name, component)
      generate_conf_file.puts(conf)
      generate_conf_file.close
      cd(base_dir) do
        sh("apt-ftparchive", "generate", generate_conf_file.path)
      end
    end

    rm_r(dists_dir.glob("Release*").collect(&:to_s))
    rm_r(base_dir.glob("*.db").collect(&:to_s))
    Tempfile.create("apt-ftparchive-release.conf") do |release_conf_file|
      conf = generate_apt_ftp_archive_release_conf(code_name, component)
      release_conf_file.puts(conf)
      release_conf_file.close
      Tempfile.create("apt-ftparchive-release") do |release_file|
        sh("apt-ftparchive",
           "-c", release_conf_file.path,
           "release",
           dists_dir.to_s,
           out: release_file.path)
        mv(release_file.path, "#{dists_dir}/Release")
      end
    end

    current_dists_dir = current_distribution_dir + "dists" + code_name
    Dir.mktmpdir do |merged_dists_dir|
      merger = APTDistsMerge::Merger.new(current_dists_dir.to_s,
                                         dists_dir.to_s,
                                         merged_dists_dir)
      merger.merge

      in_release_path = "#{merged_dists_dir}/InRelease"
      release_path = "#{merged_dists_dir}/Release"
      signed_release_path = "#{release_path}.gpg"
      sh("gpg",
         "--sign",
         "--detach-sign",
         "--armor",
         "--local-user", @release.gpg_key_id,
         "--output", signed_release_path,
         release_path)
      sh("gpg",
         "--clear-sign",
         "--local-user", @release.gpg_key_id,
         "--output", in_release_path,
         release_path)
      sh("rsync",
         "-av",
         "#{merged_dists_dir}/",
         current_dists_dir.to_s)
    end
  end
end