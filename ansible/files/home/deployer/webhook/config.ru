require "pathname"

base_dir = Pathname(__FILE__).dirname
lib_dir = base_dir + "lib"

$LOAD_PATH.unshift(lib_dir.to_s)

require "webhook-signer"

run WebhookSigner::App.new
