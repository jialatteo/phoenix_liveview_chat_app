# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Chat.Repo.insert!(%Chat.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Chat.Rooms.Room

default_room_changeset = Room.changeset(%Room{}, %{"name" => "general"})
Chat.Repo.insert(default_room_changeset)

users = [
  %{email: "adam@gmail.com", password: "password1234"},
  %{email: "bob@gmail.com", password: "password1234"}
]

Enum.each(users, fn user_attrs ->
  Chat.Users.register_user(user_attrs)
end)
