defmodule Chat.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo

  alias Chat.Messages.Message

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Message
    |> preload(:user)
    |> Repo.all()
  end

  def get_messages_from_room(room_id) do
    Message
    |> preload(:user)
    |> preload(:room)
    |> where([m], m.room_id == ^room_id)
    |> Repo.all()
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:get_latest_message, fn repo, _ ->
      case repo.one(from m in Message, order_by: [desc: m.inserted_at], limit: 1) do
        nil -> {:ok, nil}
        message -> {:ok, message}
      end
    end)
    |> Ecto.Multi.run(:create_message, fn repo, %{get_latest_message: latest_message} ->
      is_start_of_seuqence =
        case latest_message do
          nil -> true
          message -> message.user_id != attrs["user_id"]
        end

      IO.inspect(is_start_of_seuqence, label: "is_start_of_seuqence")

      changeset =
        %Message{}
        |> Message.changeset(attrs)
        |> Ecto.Changeset.put_change(:is_start_of_sequence, is_start_of_seuqence)

      case repo.insert(changeset) do
        {:ok, message} -> {:ok, message}
        error -> error
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_message: message}} ->
        broadcast({:ok, message |> Repo.preload(:user)}, :message_created)

      {:error, _failed_operation_name, changeset, _changes_so_far} ->
        broadcast({:error, changeset}, :message_created)
    end
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def subscribe(id) do
    Phoenix.PubSub.subscribe(Chat.PubSub, "messages-#{id}")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, message}, event) do
    Phoenix.PubSub.broadcast(Chat.PubSub, "messages-#{message.room_id}", {event, message})
    {:ok, message}
  end
end
