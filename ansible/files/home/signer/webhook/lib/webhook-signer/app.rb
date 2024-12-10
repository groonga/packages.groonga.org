module WebhookSigner
  class App
    def call(env)
      [200, {}, ["Hello Webhook Signer"]]
    end
  end
end
