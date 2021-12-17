defmodule TaskBunnySentry.Mixfile do
  use Mix.Project

  @version "0.3.0"
  @description "TaskBunny job failure backend that reports the error to Sentry"

  def project do
    [
      app: :task_bunny_sentry,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/homepolish/task_bunny_sentry"
      ],
      description: @description,
      package: package()
    ]
  end

  def application do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:jason, "~> 1.1", optional: true},
      {:mox, "~> 0.3", only: :test},
      {:sentry, "~> 7.0", optional: true},
      {:task_bunny, "~> 0.4", organization: "smartrent", optional: true}
    ]
  end

  defp package do
    [
      name: :task_bunny_sentry,
      organization: "smartrent",
      files: [
        # Project files
        "mix.exs",
        "README.md",
        "LICENSE.md",
        "lib"
      ],
      maintainers: [
        "Johnny Feng",
        "Erik Reedstrom",
        "James Stradling",
        "Cesario Uy"
      ],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/homepolish/task_bunny_sentry"}
    ]
  end
end
