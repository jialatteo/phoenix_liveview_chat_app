defmodule Chat.Repo.Migrations.AddIsStartOfSequence do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :is_start_of_sequence, :boolean, default: false, null: false
    end
  end
end
