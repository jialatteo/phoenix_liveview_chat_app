defmodule Chat.UserRooms.UserRoom do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_rooms" do
    field :is_admin, :boolean, default: false
    belongs_to :user, Chat.Users.User
    belongs_to :room, Chat.Rooms.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_room, attrs) do
    user_room
    |> cast(attrs, [:user_id, :room_id, :is_admin])
    |> validate_required([:user_id, :room_id])
  end
end
