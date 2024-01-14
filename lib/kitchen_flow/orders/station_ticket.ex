defmodule KitchenFlow.Orders.StationTicket do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(queued preparing ready served cancelled)

  schema "station_tickets" do
    field :station, :string
    field :status, :string, default: "queued"
    field :table_number, :integer
    field :items_payload, {:array, :map}, default: []
    field :target_prep_seconds, :integer, default: 300
    field :started_at, :utc_datetime
    field :ready_at, :utc_datetime
    field :served_at, :utc_datetime

    belongs_to :order, KitchenFlow.Orders.Order

    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [
      :order_id,
      :station,
      :status,
      :table_number,
      :items_payload,
      :target_prep_seconds,
      :started_at,
      :ready_at,
      :served_at
    ])
    |> validate_required([:order_id, :station, :status, :table_number])
    |> validate_inclusion(:status, @statuses)
  end

  def valid_transition?("queued", "preparing"), do: true
  def valid_transition?("queued", "cancelled"), do: true
  def valid_transition?("preparing", "ready"), do: true
  def valid_transition?("preparing", "cancelled"), do: true
  def valid_transition?("ready", "served"), do: true
  def valid_transition?(_, _), do: false

  def sla_breached?(%__MODULE__{status: status}, _now) when status in ["ready", "served", "cancelled"],
    do: false

  def sla_breached?(%__MODULE__{inserted_at: nil}, _now), do: false

  def sla_breached?(%__MODULE__{inserted_at: inserted_at, target_prep_seconds: target}, now) do
    elapsed = NaiveDateTime.diff(now, inserted_at, :second)
    elapsed > target
  end
end
