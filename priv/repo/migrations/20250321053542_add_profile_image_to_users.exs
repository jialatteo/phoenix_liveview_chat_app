defmodule Chat.Repo.Migrations.AddProfileImageToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile_image, :string
    end
  end
end
