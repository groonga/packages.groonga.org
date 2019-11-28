# -*- ruby -*-

require_relative "vendor/packages.red-data-tools.org/repository-task"

desc "Apply the Ansible configurations"
task :deploy do
  sh("ansible-playbook",
     "--inventory-file", "hosts",
     "ansible/playbook.yml")
end

class GroongaRepositoryTask < RepositoryTask
  def repository_name
    "groonga"
  end

  def repository_version
    # TODO: Create groonga-archive-keyring and use its version
    nil
  end

  def repository_label
    "The Groonga Project"
  end

  def repository_description
    "Groonga related packages"
  end

  def repository_url
    "https://packages.groonga.org"
  end

  def rsync_base_path
    "packages@packages.groonga.org:public"
  end

  def gpg_uids
    [
      "2701F317CFCCCB975CADE9C2624CF77434839225", # new 4092bit
      "C97E4649A2051D0CEA1A73F972A7496B45499429", # old 1024bit
    ]
  end
end

repository_task = GroongaRepositoryTask.new
repository_task.define
