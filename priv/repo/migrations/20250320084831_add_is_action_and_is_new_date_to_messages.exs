defmodule Chat.Repo.Migrations.AddIsActionAndIsNewDayToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :is_action, :boolean, default: false, null: false
      add :is_new_day, :boolean, default: false, null: false
    end
  end
end
