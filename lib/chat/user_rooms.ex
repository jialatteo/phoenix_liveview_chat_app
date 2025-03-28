defmodule Chat.UserRooms do
  @moduledoc """
  The UserRooms context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo
  alias Chat.UserRooms.UserRoom
  alias Chat.Messages

  @doc """
  Returns the list of users_rooms.

  ## Examples

      iex> list_users_rooms()
      [%UserRoom{}, ...]

  """
  def list_users_rooms do
    Repo.all(UserRoom)
  end

  def user_room_exist(%{"room_id" => room_id, "user_id" => user_id}) do
    UserRoom
    |> where([ur], ur.user_id == ^user_id and ur.room_id == ^room_id)
    |> Repo.exists?()
  end

  def get_users_in_room(room_id) do
    UserRoom
    |> where([ur], ur.room_id == ^room_id)
    |> preload(:user)
    |> Repo.all()
    |> Enum.map(& &1.user)
  end

  def remove_user_from_room(user_id, room_id) do
    user_room = Repo.get_by(UserRoom, user_id: user_id, room_id: room_id)

    case user_room do
      nil ->
        {:error, :not_found}

      _ ->
        Repo.transaction(fn ->
          Repo.delete!(user_room)

          remaining_users =
            Repo.aggregate(from(ur in UserRoom, where: ur.room_id == ^room_id), :count, :id)

          if remaining_users == 0 do
            Repo.delete_all(from(r in Chat.Rooms.Room, where: r.id == ^room_id))
          end

          message_params = %{
            "user_id" => user_id,
            "room_id" => room_id,
            "is_action" => true,
            "content" => "has left the room."
          }

          case Messages.create_message(message_params) do
            {:ok, message} ->
              broadcast(
                {:ok, %{"message" => message, "user_room" => user_room}, :room_removed_user}
              )

            {:error, changeset} ->
              IO.inspect(changeset, label: "Error creating message")
              Repo.rollback(:message_creation_failed)
          end
        end)
    end
  end

  def add_users_to_room(users, room_id) do
    users
    |> Enum.map(fn user ->
      %UserRoom{
        user_id: user.id,
        room_id: room_id
      }
    end)
    |> Enum.each(fn user_room ->
      case Repo.insert(user_room) do
        {:ok, user_room} ->
          message_params = %{
            "user_id" => user_room.user_id,
            "room_id" => room_id,
            "is_action" => true,
            "content" => "has joined the room."
          }

          case Messages.create_message(message_params) do
            {:ok, message} ->
              broadcast(
                {:ok, %{"user_room" => user_room, "message" => message}, :room_added_user}
              )

              broadcast({:ok, user_room}, :user_added_room)

            {:error, changeset} ->
              IO.inspect(changeset.errors, label: "Failed to create message")
              Repo.rollback(:message_creation_failed)
          end

        {:error, changeset} = error ->
          broadcast(error, :room_added_user)
          broadcast(error, :user_added_room)
          IO.inspect(changeset.errors, label: "Failed to insert UserRoom")
      end
    end)
  end

  @doc """
  Gets a single user_room.

  Raises `Ecto.NoResultsError` if the User room does not exist.

  ## Examples

      iex> get_user_room!(123)
      %UserRoom{}

      iex> get_user_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_room!(id), do: Repo.get!(UserRoom, id)

  @doc """
  Creates a user_room.

  ## Examples

      iex> create_user_room(%{field: value})
      {:ok, %UserRoom{}}

      iex> create_user_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_room(attrs \\ %{}) do
    %UserRoom{}
    |> UserRoom.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_room.

  ## Examples

      iex> update_user_room(user_room, %{field: new_value})
      {:ok, %UserRoom{}}

      iex> update_user_room(user_room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_room(%UserRoom{} = user_room, attrs) do
    user_room
    |> UserRoom.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_room.

  ## Examples

      iex> delete_user_room(user_room)
      {:ok, %UserRoom{}}

      iex> delete_user_room(user_room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_room(%UserRoom{} = user_room) do
    Repo.delete(user_room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_room changes.

  ## Examples

      iex> change_user_room(user_room)
      %Ecto.Changeset{data: %UserRoom{}}

  """
  def change_user_room(%UserRoom{} = user_room, attrs \\ %{}) do
    UserRoom.changeset(user_room, attrs)
  end

  def subscribe({:user_id, user_id}) do
    Phoenix.PubSub.subscribe(Chat.PubSub, "user-#{user_id}")
  end

  def subscribe({:room_id, room_id}) do
    Phoenix.PubSub.subscribe(Chat.PubSub, "room-#{room_id}")
  end

  defp broadcast({:error, _changeset} = error, _event), do: error

  defp broadcast({:ok, user_room}, :user_added_room) do
    Phoenix.PubSub.broadcast(
      Chat.PubSub,
      "user-#{user_room.user_id}",
      {:user_added_room, user_room.room_id}
    )

    {:ok, user_room.room_id}
  end

  defp broadcast({:ok, %{"message" => message, "user_room" => user_room}, :room_added_user}) do
    Phoenix.PubSub.broadcast(
      Chat.PubSub,
      "room-#{user_room.room_id}",
      {:room_added_user, user_room.user_id, message}
    )

    {:ok, user_room.user_id, message}
  end

  defp broadcast({:ok, %{"message" => message, "user_room" => user_room}, :room_removed_user}) do
    Phoenix.PubSub.broadcast(
      Chat.PubSub,
      "room-#{user_room.room_id}",
      {:room_removed_user, user_room.user_id, message}
    )

    {:ok, user_room.user_id, message}
  end
end
