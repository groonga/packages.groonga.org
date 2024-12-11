module Deployer
  class App
    def call(env)
      [200, {}, ["Hello deployer"]]
    end
  end
end
