defmodule Mix.Tasks.EveOnline.GetUniverseNames do
  use Mix.Task

  @base_url :"https://esi.evetech.net/latest"

  @impl Mix.Task
  def run(_) do
    Application.ensure_all_started(:hackney)

    Mix.shell().info("Program begins")

    with {:ok, market} <- get_market_orders(),
         {:ok, _names} <- get_universe_names(market) do
      Mix.shell().info("Program done")
    end
  end

  def get_market_orders do
    url =
      Enum.join(
        [@base_url, "markets/10000002/orders/?datasource=tranquility&order_type=all&page=1"],
        "/"
      )

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: market_response_body}} ->
        Poison.decode(market_response_body)

      {:ok, %{status_code: other}} ->
        Mix.shell().error("Error contacting market endpoint: HTTP CODE " <> to_string(other))
        :error

      {:error, %HTTPoison.Error{:__exception__ => true, :id => nil, :reason => message}} ->
        Mix.shell().error("Error contacting market endpoint: " <> message)
        :error
    end
  end

  def get_universe_names(market_orders) do
    Mix.shell().info("Parsing market orders " <> inspect(market_orders))
    url = Enum.join([@base_url, "universe/names/?datasource=tranquility"], "/")

    case HTTPoison.post(url, [], %{}) do
      {:ok, %{status_code: 200, body: market_response_body}} ->
        Poison.decode(market_response_body)

      {:ok, %{status_code: other}} ->
        Mix.shell().error("Error contacting universe endpoint: HTTP CODE " <> to_string(other))
        :error

      {:error, %HTTPoison.Error{:__exception__ => true, :id => nil, :reason => message}} ->
        Mix.shell().error("Error contacting universe endpoint: " <> message)
        :error
    end
  end
end
