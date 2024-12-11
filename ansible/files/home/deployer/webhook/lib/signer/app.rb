module Signer
  class App
    def call(env)
      [200, {}, ["Hello Signer"]]
    end
  end
end
