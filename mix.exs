defmodule Wordex.MixProject do
    use Mix.Project

    Mix.env(:prod)
    def project do
        [
            app: :wordex,
            version: "1.0.1",
            elixir: "~> 1.17",
            start_permanent: Mix.env() == :prod,
            deps: deps(),
            escript: [main_module: Wordex.Exec]
        ]
    end

    # Run "mix help compile.app" to learn about applications.
    def application do
        [
            extra_applications: [:logger]
        ]
    end

    # Run "mix help deps" to learn about dependencies.
    defp deps do
        [
            # {:dep_from_hexpm, "~> 0.3.0"},
            # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
            {:httpoison, "~> 2.2"},
            {:simetric, "~> 0.2.0"},
            {:unicode, "~> 1.19"}
        ]
    end
end
