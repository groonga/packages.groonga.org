# -*- ruby -*-

require_relative "helper"
require_relative "vendor/packages.red-data-tools.org/repository-task"

groonga_repository = ENV["GROONGA_REPOSITORY"]
if groonga_repository.nil?
  raise "Specify GROONGA_REPOSITORY environment variable"
end
require "#{groonga_repository}/packages/repository-helper"

user = ENV["ANSIBLE_GPG_USER"] || ENV["USER"]
file "ansible/password" => "ansible/password.#{user}.asc" do |task|
  sh("gpg",
     "--output", task.name,
     "--decrypt", task.prerequisites.first)
  chmod(0600, task.name)
end

encrypted_files = [
  "ansible/vars/private.yml",
]
encrypted_files.each do |encrypted_file|
  desc "Edit #{encrypted_file}"
  task File.basename(encrypted_file) => "ansible/password" do |task|
    sh("ansible-vault",
       "edit",
       "--vault-password-file", "ansible/password",
       encrypted_file)
  end
end

desc "Apply the Ansible configurations"
task :deploy => "ansible/password" do
  sh("ansible-playbook",
     "--inventory-file", "hosts",
     "--vault-password-file", "ansible/password",
     "ansible/playbook.yml")
end

class GroongaRepositoryTask < RepositoryTask
  include RepositoryHelper
  include Helper::RepositoryDetail

  def repository_gpg_key_id
    repository_gpg_key_ids.first
  end

  def yum_targets
    [
      ["almalinux", "10"],
      ["almalinux", "9"],
      ["almalinux", "8"],
      ["amazon-linux", "2023"],
    ]
  end
end

repository_task = GroongaRepositoryTask.new
repository_task.define
