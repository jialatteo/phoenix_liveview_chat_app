defmodule Chat.UserRoomsTest do
  use Chat.DataCase

  alias Chat.UserRooms

  describe "users_rooms" do
    alias Chat.UserRooms.UserRoom

    import Chat.UserRoomsFixtures

    @invalid_attrs %{}

    test "list_users_rooms/0 returns all users_rooms" do
      user_room = user_room_fixture()
      assert UserRooms.list_users_rooms() == [user_room]
    end

    test "get_user_room!/1 returns the user_room with given id" do
      user_room = user_room_fixture()
      assert UserRooms.get_user_room!(user_room.id) == user_room
    end

    test "create_user_room/1 with valid data creates a user_room" do
      valid_attrs = %{}

      assert {:ok, %UserRoom{} = user_room} = UserRooms.create_user_room(valid_attrs)
    end

    test "create_user_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UserRooms.create_user_room(@invalid_attrs)
    end

    test "update_user_room/2 with valid data updates the user_room" do
      user_room = user_room_fixture()
      update_attrs = %{}

      assert {:ok, %UserRoom{} = user_room} = UserRooms.update_user_room(user_room, update_attrs)
    end

    test "update_user_room/2 with invalid data returns error changeset" do
      user_room = user_room_fixture()
      assert {:error, %Ecto.Changeset{}} = UserRooms.update_user_room(user_room, @invalid_attrs)
      assert user_room == UserRooms.get_user_room!(user_room.id)
    end

    test "delete_user_room/1 deletes the user_room" do
      user_room = user_room_fixture()
      assert {:ok, %UserRoom{}} = UserRooms.delete_user_room(user_room)
      assert_raise Ecto.NoResultsError, fn -> UserRooms.get_user_room!(user_room.id) end
    end

    test "change_user_room/1 returns a user_room changeset" do
      user_room = user_room_fixture()
      assert %Ecto.Changeset{} = UserRooms.change_user_room(user_room)
    end
  end
end
