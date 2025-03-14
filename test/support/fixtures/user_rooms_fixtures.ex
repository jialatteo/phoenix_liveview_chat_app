defmodule Chat.UserRoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.UserRooms` context.
  """

  @doc """
  Generate a user_room.
  """
  def user_room_fixture(attrs \\ %{}) do
    {:ok, user_room} =
      attrs
      |> Enum.into(%{

      })
      |> Chat.UserRooms.create_user_room()

    user_room
  end
end
