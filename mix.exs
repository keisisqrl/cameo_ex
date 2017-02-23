defmodule CameoEx.Mixfile do
  use Mix.Project

  def project do
    [app: :cameo_ex,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:sasl, :logger],
     mod: {CameoEx, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:discord_ex, "~> 1.1.8"},
      {:fsm, "~> 0.3.0"}
    ]
  end
end
