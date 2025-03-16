defmodule Chat.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo

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
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:room, Room.changeset(%Room{}, %{"name" => name}))
    |> Ecto.Multi.insert(:user_room, fn %{room: room} ->
      UserRoom.changeset(%UserRoom{}, %{
        "user_id" => user_id,
        "room_id" => room.id,
        "is_admin" => true
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{room: room}} ->
        broadcast({:ok, room}, :room_created)

      {:error, _step, reason, _changes_so_far} ->
        {:error, reason}
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

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, room}, event) do
    Phoenix.PubSub.broadcast(Chat.PubSub, "rooms", {event, room})
    {:ok, room}
  end
end
