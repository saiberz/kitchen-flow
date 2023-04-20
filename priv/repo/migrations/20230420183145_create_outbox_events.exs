defmodule KitchenFlow.Repo.Migrations.CreateOutboxEvents do
  use Ecto.Migration

  def change do
    create table(:outbox_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_type, :string, null: false
      add :routing_key, :string, null: false
      add :payload, :map, null: false
      add :status, :string, null: false, default: "pending"
      add :attempts, :integer, null: false, default: 0
      add :last_error, :string
      add :published_at, :utc_datetime

      timestamps()
    end

    create index(:outbox_events, [:status, :inserted_at])
  end
end
