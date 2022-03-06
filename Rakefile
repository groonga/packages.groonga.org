# -*- ruby -*-

require_relative "helper"
require_relative "vendor/groonga/packages/repository-helper"
require_relative "vendor/packages.red-data-tools.org/repository-task"

desc "Apply the Ansible configurations"
task :deploy do
  sh("ansible-playbook",
     "--inventory-file", "hosts",
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
      ["almalinux", "8"],
      ["amazon-linux", "2"],
      ["centos", "7"],
    ]
  end
end

repository_task = GroongaRepositoryTask.new
repository_task.define
