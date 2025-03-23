defmodule Chat.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo
  alias Chat.Messages

  alias Chat.Rooms.Room
  alias Chat.UserRooms.UserRoom

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
  end

  def list_rooms_of_user(user_id) do
    Room
    |> join(:inner, [r], ur in UserRoom, on: ur.room_id == r.id)
    |> where([r, ur], ur.user_id == ^user_id)
    |> select([r], r)
    |> Repo.all()
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(%{"user_id" => user_id, "name" => name} \\ %{}) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:insert_room, Room.changeset(%Room{}, %{"name" => name}))
      |> Ecto.Multi.insert(:insert_user_room, fn %{insert_room: room} ->
        UserRoom.changeset(%UserRoom{}, %{
          "user_id" => user_id,
          "room_id" => room.id,
          "is_admin" => true
        })
      end)
      |> Ecto.Multi.run(:insert_join_message, fn _repo, %{insert_user_room: user_room} ->
        message_params = %{
          "user_id" => user_room.user_id,
          "room_id" => user_room.room_id,
          "is_action" => true,
          "content" => "has joined the room."
        }

        Messages.create_message(message_params)
      end)

    case Repo.transaction(multi) do
      {:ok, %{insert_room: room, insert_join_message: message}} ->
        broadcast({:ok, room, message}, :room_created)

      {:error, _failed_operation_name, changeset, _changes_so_far} ->
        broadcast({:error, changeset}, :room_created)
    end
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(Chat.PubSub, "rooms")
  end

  defp broadcast({:error, _changeset} = error, _event), do: error

  defp broadcast({:ok, room, message}, event) do
    Phoenix.PubSub.broadcast(Chat.PubSub, "rooms", {event, room, message})
    {:ok, room, message}
  end
end
