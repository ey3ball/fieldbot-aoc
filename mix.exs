defmodule Aoc.MixProject do
  use Mix.Project

  def project do
    [
      app: :aoc,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Aoc, []},
      extra_applications: [:logger, :mongodb, :poolboy]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exirc, "~> 2.0.0"},
      {:hackney, "~> 1.16.0"},
      {:jason, "~> 1.2"},
      {:quantum, "~> 3.0"},
      {:mongodb, " >= 0.0.0"},
      {:poolboy, " >= 0.0.0"},
      {:floki, "~> 0.29.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
