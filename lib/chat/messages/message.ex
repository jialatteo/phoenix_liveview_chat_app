defmodule Chat.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    field :is_start_of_sequence, :boolean, default: false
    belongs_to :user, Chat.Users.User
    belongs_to :room, Chat.Rooms.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :is_start_of_sequence, :user_id, :room_id])
    |> validate_required([:content, :user_id, :room_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:room)
  end
end
