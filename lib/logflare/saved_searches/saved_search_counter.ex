defmodule Logflare.SavedSearchCounter do
  @moduledoc false
  use TypedEctoSchema
  import Ecto.Changeset
  alias Logflare.SavedSearch

  typed_schema "saved_search_counters" do
    field :timestamp, :utc_datetime
    belongs_to :saved_search, SavedSearch
    field :granularity, :string, default: "hour"
    field :tailing_count, :integer
    field :non_tailing_count, :integer
  end

  def changeset(counter, attrs \\ %{}) do
    counter
    |> cast(attrs, [:timestamp])
    |> unique_constraint(:datetime, name: :saved_search_counters_timestamp_source_id_granularity)
  end
end
