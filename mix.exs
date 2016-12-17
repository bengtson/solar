defmodule Sun.Mixfile do
  use Mix.Project

  def project do
    [
      app: :solar,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: "Solar Event Calculator",
      package: package,
      deps: deps(),

      # Docs
      name: "solar",
      source_url: "https://github.com/bengtson/solar",
      docs:
        [
          main: "Solar", # The main page in the docs
          extras: ["README.md"]
        ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:timex]]
  end

  def package do
    [
      maintainers: ["Michael Bengtson"],
      licenses: ["Apache 2 (see the file LICENSE for details)"],
      links: %{"GitHub" => "https://github.com/bengtson/solar"}
    ]
  end
  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:latlong, "~> 0.1.0"},
      {:timex, "~> 3.0"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end
end
