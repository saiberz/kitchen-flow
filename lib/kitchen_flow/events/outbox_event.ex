defmodule KitchenFlow.Events.OutboxEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(pending published failed)

  schema "outbox_events" do
    field :event_type, :string
    field :routing_key, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :attempts, :integer, default: 0
    field :last_error, :string
    field :published_at, :utc_datetime

    timestamps()
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:event_type, :routing_key, :payload, :status, :attempts, :last_error, :published_at])
    |> validate_required([:event_type, :routing_key, :payload, :status])
    |> validate_inclusion(:status, @statuses)
  end
end
