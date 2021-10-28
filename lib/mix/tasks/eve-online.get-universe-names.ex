defmodule Mix.Tasks.EveOnline.GetUniverseNames do
  use Mix.Task

  @base_url :"https://esi.evetech.net/latest"

  @market_id 10_000_002

  @order_type "all"

  @starting_page 1

  @datasource "tranquility"

  @impl Mix.Task
  def run(_) do
    Application.ensure_all_started(:hackney)

    Mix.shell().info("Program start")

    with {:ok, market} <- get_market_orders(@datasource, @market_id, @order_type, @starting_page),
         {:ok, names} <- get_universe_names(market) do
      names = Enum.uniq(Enum.map(names, fn n -> n["name"] end))
      Mix.shell().info("Names: " <> inspect(names))
    end

    Mix.shell().info("Program end")
  end

  def get_market_orders(datasource, market_id, order_type, page) do
    url =
      Enum.join(
        [@base_url, "markets", market_id, make_market_orders_url(datasource, order_type, page)],
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

  def make_market_orders_url(datasource, order_type, page) do
    "orders/?datasource=" <>
      datasource <> "&" <> "order_type=" <> order_type <> "&" <> "page=" <> to_string(page)
  end

  def get_universe_names(market_orders) do
    type_ids = Enum.uniq(Enum.map(market_orders, fn order -> order["type_id"] end))
    body = Poison.encode!(type_ids)
    url = Enum.join([@base_url, "universe/names/?datasource=tranquility"], "/")

    case HTTPoison.post(url, body, [{"Content-type", "application/json"}], []) do
      {:ok, %{status_code: 200, body: market_response_body}} ->
        Poison.decode(market_response_body)

      {:ok, %{status_code: other, body: body}} ->
        Mix.shell().error(
          "Error contacting universe endpoint: HTTP CODE " <>
            to_string(other) <> " -> " <> inspect(body)
        )

        :error

      {:error, %HTTPoison.Error{:__exception__ => true, :id => nil, :reason => message}} ->
        Mix.shell().error("Error contacting universe endpoint: " <> message)
        :error
    end
  end
end
