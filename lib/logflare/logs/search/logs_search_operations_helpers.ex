defmodule Logflare.Logs.SearchOperations.Helpers do
  @moduledoc false
  alias Logflare.Google.BigQuery.GenUtils
  alias Logflare.EctoQueryBQ
  alias Logflare.Source
  alias GoogleApi.BigQuery.V2.Model.QueryRequest
  alias Logflare.Google.BigQuery.{GenUtils, SchemaUtils}
  alias Logflare.Google.BigQuery
  alias Logflare.{Source, Sources, EctoQueryBQ}
  @query_request_timeout 60_000
  @type minmax :: %{min: DateTime.t(), max: DateTime.t(), message: nil | String.t()}
  @default_open_interval_length 250

  @spec get_min_max_filter_timestamps([FR.t()], atom()) :: minmax()
  def get_min_max_filter_timestamps([], chart_period) do
    {min, max} = default_min_max_for_tailing_chart_period(chart_period)
    %{min: min, max: max, message: nil}
  end

  def get_min_max_filter_timestamps([_tsf] = ts_filters, chart_period) do
    {min, max} =
      ts_filters
      |> override_min_max_for_open_intervals(chart_period)
      |> min_max_timestamps()

    message = generate_message(chart_period)

    %{min: min, max: max, message: message}
  end

  def get_min_max_filter_timestamps(ts_filters, _chart_period) when length(ts_filters) > 1 do
    {min, max} =
      ts_filters
      |> Enum.map(& &1.value)
      |> min_max_timestamps()

    %{min: min, max: max, message: nil}
  end

  def default_min_max_for_tailing_chart_period(period) when is_atom(period) do
    tick_count = default_period_tick_count(period)
    shift_key = to_timex_shift_key(period)

    from = Timex.shift(Timex.now(), [{shift_key, -tick_count + 1}])
    {from, Timex.now()}
  end

  def min_max_timestamps(timestamps) do
    Enum.min_max_by(timestamps, &Timex.to_unix/1)
  end

  @ops ~w[> >=]a
  defp override_min_max_for_open_intervals([%{operator: op, value: ts}], period)
       when op in @ops do
    shift = [{to_timex_shift_key(period), @default_open_interval_length}]

    max = ts |> Timex.shift(shift)

    max =
      if Timex.compare(max, Timex.now()) > 0 do
        Timex.now()
      else
        max
      end

    [ts, max]
  end

  @ops ~w[< <=]a
  defp override_min_max_for_open_intervals([%{operator: op, value: ts}], period)
       when op in @ops do
    shift = [{to_timex_shift_key(period), -@default_open_interval_length}]
    [ts |> Timex.shift(shift), ts]
  end

  @spec to_timex_shift_key(:day | :hour | :minute | :second) ::
          :days | :hours | :minutes | :seconds
  def to_timex_shift_key(period) do
    case period do
      :day -> :days
      :hour -> :hours
      :minute -> :minutes
      :second -> :seconds
    end
  end

  def default_period_tick_count(period) do
    case period do
      :day -> 31
      :hour -> 168
      :minute -> 120
      :second -> 180
    end
  end

  def convert_timestamp_timezone(row, user_timezone) do
    Map.update!(row, "timestamp", &Timex.Timezone.convert(&1, user_timezone))
  end

  def ecto_query_to_sql(%Ecto.Query{} = query, %Source{} = source) do
    %{bigquery_dataset_id: bq_dataset_id} = GenUtils.get_bq_user_info(source.token)
    {sql, params} = EctoQueryBQ.SQL.to_sql_params(query)
    sql_and_params = {EctoQueryBQ.SQL.substitute_dataset(sql, bq_dataset_id), params}
    sql_string = EctoQueryBQ.SQL.sql_params_to_sql(sql_and_params)
    %{sql_with_params: sql, params: params, sql_string: sql_string}
  end

  def query_with_params(sql, params, opts \\ [])
      when is_binary(sql) and is_list(params) do
    query_request = %QueryRequest{
      query: sql,
      useLegacySql: false,
      useQueryCache: true,
      parameterMode: "POSITIONAL",
      queryParameters: params,
      dryRun: false,
      timeoutMs: @query_request_timeout
    }

    with {:ok, response} <- BigQuery.query(query_request) do
      AtomicMap.convert(response, %{safe: false})
    else
      errtup -> errtup
    end
  end

  def generate_message(period) do
    "Your timestamp filter is an unbounded interval. Max number of chart ticks is limited to 250 #{
      to_timex_shift_key(period)
    }."
  end
end