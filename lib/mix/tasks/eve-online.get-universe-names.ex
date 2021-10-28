defmodule Mix.Tasks.EveOnline.GetUniverseNames do
  use Mix.Task

  @base_url :"https://esi.evetech.net/latest"

  # Can i change this task to fetch all? Collect all pages?
  # i dont think I should do it because HTTPoison fetches the complete json
  # and it would take up too much memory.
  # Out of Scope
  @default_page 1

  @impl Mix.Task
  def run(args) do
    case args do
      [
        "datasource" <> "=" <> datasource,
        "region_id" <> "=" <> region_id,
        "order_type" <> "=" <> order_type
      ] ->
        Application.ensure_all_started(:hackney)

        Mix.shell().info("Program start")

        response =
          with {:ok, orders} <-
                 get_market_orders(datasource, region_id, order_type, @default_page),
               type_ids <- get_unique_type_ids(orders),
               {:ok, objects} <- get_universe_names(datasource, type_ids),
               sorted_object_names <- get_sorted_object_names(objects) do
            Enum.each(sorted_object_names, fn o -> Mix.shell().info(o) end)

            Mix.shell().info(
              "Found " <> to_string(length(sorted_object_names)) <> " unique object names"
            )
          end

        Mix.shell().info("Result: " <> inspect(response))

        Mix.shell().info("Program end")

      other ->
        Mix.shell().error(
          "Usage: mix <task> datasource=your_datasource region_id=your_region_id order_type=your_order_type \n" <>
            "Provided: " <> inspect(other)
        )
    end
  end

  def get_unique_type_ids(orders) do
    Enum.map(orders, fn order -> order["type_id"] end)
    |> Enum.uniq()
  end

  def get_sorted_object_names(objects) do
    Enum.map(objects, fn n -> n["name"] end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def get_market_orders(datasource, region_id, order_type, page) do
    url =
      "orders/?" <>
        Enum.join(
          [
            "datasource=" <> datasource,
            "order_type=" <> order_type,
            "page=" <> to_string(page)
          ],
          "&"
        )

    url =
      Enum.join(
        [@base_url, "markets", region_id, url],
        "/"
      )

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: market_response_body}} ->
        Poison.decode(market_response_body)

      {:ok, %{status_code: other, body: body}} ->
        Mix.shell().error(
          "Error contacting market endpoint: HTTP CODE " <>
            to_string(other) <> " -> " <> inspect(body)
        )

        :error

      {:error, %HTTPoison.Error{:__exception__ => true, :id => nil, :reason => message}} ->
        Mix.shell().error("Error contacting market endpoint: " <> message)
        :error
    end
  end

  def get_universe_names(datasource, type_ids) do
    url = Enum.join([@base_url, "universe/names/?datasource=" <> datasource], "/")

    case HTTPoison.post(url, Poison.encode!(type_ids), [{"Content-type", "application/json"}], []) do
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
