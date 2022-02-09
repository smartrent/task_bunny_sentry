defmodule TaskBunnySentry.Mixfile do
  use Mix.Project

  @version "0.3.1"
  @description "TaskBunny job failure backend that reports the error to Sentry"
  @source_url "https://github.com/smartrent/task_bunny_sentry"

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
        extras: ["README.md", "CHANGELOG.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: @source_url
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
      {:bypass, "~> 2.1", only: :test},
      {:ex_doc, "~> 0.28", only: :dev},
      {:hackney, "~> 1.8", optional: true},
      {:jason, "~> 1.1", optional: true},
      {:plug, "~> 1.0", only: :test},
      {:sentry, "~> 8.0", optional: true},
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
      licenses: ["MIT"],
      links: %{
        "Github" => @source_url,
        "Changelog" => @source_url <> "/blob/master/CHANGELOG.md"
      }
    ]
  end
end
