defmodule Chat.Repo.Migrations.AddIsAdminToUsersRooms do
  use Ecto.Migration

  def change do
    alter table(:users_rooms) do
      add :is_admin, :boolean, default: false, null: false
    end
  end
end
