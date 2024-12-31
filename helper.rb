module Helper
  module RepositoryDetail
    def repository_version
      "2024.12.31"
    end

    def repository_name
      "groonga"
    end

    # This must be synced with
    # ansible/files/home/packages/tasks/repository-task.rb
    def repository_label
      "The Groonga Project"
    end

    # This must be synced with
    # ansible/files/home/packages/tasks/repository-task.rb
    def repository_description
      "Groonga related packages"
    end

    def repository_url
      "https://packages.groonga.org"
    end
  end
end
