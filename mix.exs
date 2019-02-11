defmodule Julex.MixProject do
  use Mix.Project

  def project do
    [
      app: :julex,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Julex, []}
    ]
  end

  defp deps do
    []
  end
end
