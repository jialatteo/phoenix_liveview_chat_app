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

users = [
  %{email: "adam@gmail.com", password: "password1234"},
  %{email: "bob@gmail.com", password: "password1234"}
]

Enum.each(users, fn user_attrs ->
  Chat.Users.register_user(user_attrs)
end)

Chat.Rooms.create_room(%{"user_id" => 1, "name" => "general"})
