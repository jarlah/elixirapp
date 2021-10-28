defmodule Mix.Tasks.EveOnline.GetObjectNames do
  use Mix.Task

  @type datasource :: String.t()
  @type region_id :: integer()
  @type order_type :: String.t()
  @type page :: integer()

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
        "region_id" <> "=" <> region_id_str,
        "order_type" <> "=" <> order_type
      ] ->
        Application.ensure_all_started(:hackney)

        Mix.shell().info("Program start")

        # Either monad! xD
        response =
          with {:ok, region_id} <- safe_parse_integer(region_id_str),
               {:ok, orders} <-
                 get_market_orders(datasource, region_id, order_type, @default_page),
               type_ids <- get_unique_type_ids(orders),
               {:ok, objects} <- get_universe_objects_by_type_ids(datasource, type_ids),
               sorted_object_names <- get_sorted_object_names(objects) do
            Enum.each(sorted_object_names, fn o -> Mix.shell().info(o) end)

            Mix.shell().info(
              "Found " <> to_string(length(sorted_object_names)) <> " unique object names"
            )
          end

        case response do
          :ok -> Mix.shell().info("OK")
          {:error, message} -> Mix.shell().error("Error occured: " <> message)
          other -> Mix.shell().warning("Unknown result: " <> other)
        end

        Mix.shell().info("Program end")

      other ->
        Mix.shell().error(
          "Usage: mix <task> datasource=your_datasource region_id=your_region_id order_type=your_order_type \n" <>
            "Provided: " <> inspect(other)
        )
    end
  end

  @spec safe_parse_integer(String.t()) :: {:error, String.t()} | {:ok, integer()}
  def safe_parse_integer(str) do
    case Integer.parse(str, 10) do
      {int, _} -> {:ok, int}
      :error -> {:error, "Failed to parse str"}
    end
  end

  @spec get_unique_type_ids(list(map())) :: list(integer())
  def get_unique_type_ids(orders) do
    # TODO should i trust that type_id is a number?
    Enum.map(orders, fn order -> order["type_id"] end)
    |> Enum.uniq()
  end

  @spec get_sorted_object_names(list(map())) :: list(String.t())
  def get_sorted_object_names(objects) do
    Enum.map(objects, fn n -> n["name"] end)
    # is this optimal? With 1000 records its not problem, but with 1mill it might be
    # sort first or distinct first? hmmm
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec get_market_orders(datasource(), region_id(), order_type(), integer()) ::
          {:error, String.t()} | {:ok, list(map())}
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
        {:error,
         "Error contacting market endpoint: HTTP CODE " <>
           to_string(other) <> " -> " <> inspect(body)}

      {:error, %HTTPoison.Error{:__exception__ => true, :id => nil, :reason => message}} ->
        {:error, "Error contacting market endpoint: " <> message}
    end
  end

  @spec get_universe_objects_by_type_ids(datasource(), list(integer())) ::
          {:error, String.t()} | {:ok, list(map())}
  def get_universe_objects_by_type_ids(datasource, type_ids) do
    url = Enum.join([@base_url, "universe/namess/?datasource=" <> datasource], "/")

    case HTTPoison.post(url, Poison.encode!(type_ids), [{"Content-type", "application/json"}], []) do
      {:ok, %{status_code: 200, body: market_response_body}} ->
        Poison.decode(market_response_body)

      {:ok, %{status_code: other, body: body}} ->
        {:error,
         "Error contacting universe endpoint: HTTP CODE " <>
           to_string(other) <> " -> " <> inspect(body)}

      {:error, %HTTPoison.Error{:__exception__ => true, :id => nil, :reason => message}} ->
        {:error, "Error contacting universe endpoint: " <> message}
    end
  end
end
