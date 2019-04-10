defmodule Janus.WS.MixProject do
  use Mix.Project

  @version "0.1.2"

  def project do
    [
      app: :janus_ws,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:websockex, "~> 0.4.2"},
      {:dialyxir, "~> 1.0-rc", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    WebSocket client for Janus WebRTC Gateway
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/syfgkjasdkn/janus_ws"}
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "Janus.WS",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/janus_ws",
      source_url: "https://github.com/syfgkjasdkn/janus_ws",
      extras: [
        "README.md"
      ]
    ]
  end
end
