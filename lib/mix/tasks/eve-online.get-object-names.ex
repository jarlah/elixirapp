defmodule Mix.Tasks.EveOnline.GetObjectNames do
  use Mix.Task

  @type datasource :: String.t()
  @type region_id :: integer()
  @type order_type :: String.t()
  @type page :: integer()
  @type api_response :: {:error, HTTPoison.Error.t()} | {:ok, HTTPoison.Response.t()}
  @type either_list :: {:error, String.t()} | {:ok, list(map())}
  @spec handle(api_response(), String.t()) :: either_list()
  @spec get_unique_object_names_sorted(list(map())) :: list(String.t())
  @spec get_universe_objects_by_type_ids(datasource(), list(integer())) :: either_list()
  @spec get_market_orders(datasource(), region_id(), order_type(), page()) :: either_list()
  @spec get_unique_type_ids(list(map())) :: list(integer())
  @spec safe_parse_integer(String.t()) :: {:error, String.t()} | {:ok, integer()}
  @spec print_result({:error, String.t()} | {:ok, list(String.t())}) :: any()

  @base_url :"https://esi.evetech.net/latest"

  @impl Mix.Task
  def run(args) do
    case args do
      [
        "datasource=" <> datasource,
        "region_id=" <> region_id_str,
        "order_type=" <> order_type,
        "page=" <> page_str
      ] ->
        Application.ensure_all_started(:hackney)

        with {:ok, region_id} <- safe_parse_integer(region_id_str),
             {:ok, page} <- safe_parse_integer(page_str),
             {:ok, orders} <- get_market_orders(datasource, region_id, order_type, page),
             type_ids <- get_unique_type_ids(orders),
             {:ok, objects} <- get_universe_objects_by_type_ids(datasource, type_ids),
             object_names <- get_unique_object_names_sorted(objects) do
          {:ok, object_names}
        end
        |> print_result()

      other ->
        Mix.shell().error(
          "Usage: mix <task> datasource=your_datasource region_id=your_region_id order_type=your_order_type \n" <>
            "Provided: " <> inspect(other)
        )
    end
  end

  def print_result({:error, message}),
    do: Mix.shell().error("Error occured: " <> inspect(message))

  def print_result({:ok, names}) do
    Enum.each(names, fn n -> Mix.shell().info(n) end)
    Mix.shell().info("Found " <> to_string(length(names)) <> " unique object names")
  end

  def safe_parse_integer(str) do
    case Integer.parse(str, 10) do
      {int, _} -> {:ok, int}
      :error -> {:error, "Failed to parse " <> str}
    end
  end

  def get_unique_type_ids(orders),
    do:
      Enum.map(orders, fn order -> order["type_id"] end)
      |> Enum.uniq()

  def get_market_orders(datasource, region_id, order_type, page),
    do:
      (to_string(@base_url) <> "/markets/" <> to_string(region_id) <> "/orders")
      |> HTTPoison.get([],
        params: %{
          datasource: datasource,
          order_type: order_type,
          page: page
        }
      )
      |> handle("market")

  def get_universe_objects_by_type_ids(datasource, type_ids),
    do:
      (to_string(@base_url) <> "/universe/names")
      |> HTTPoison.post(Poison.encode!(type_ids), [{"Content-type", "application/json"}],
        params: %{datasource: datasource}
      )
      |> handle("universe")

  def get_unique_object_names_sorted(objects),
    do:
      Enum.map(objects, fn n -> n["name"] end)
      |> Enum.uniq()
      |> Enum.sort()

  def handle({:error, %{:reason => message}}, type),
    do: {:error, "Error contacting " <> type <> " endpoint: " <> inspect(message)}

  def handle({:ok, %{status_code: 200, body: body}}, _), do: Poison.decode(body)

  def handle({:ok, %{status_code: other, body: body}}, type),
    do:
      {:error,
       "Error contacting " <>
         type <>
         " endpoint: HTTP CODE " <>
         to_string(other) <> " -> " <> inspect(body)}
end
