use Mix.Config

config :julex, Julex.Worker,
  project: "test/TestJulex",
  module: "TestJulex"

import_config "#{Mix.env()}.exs"
