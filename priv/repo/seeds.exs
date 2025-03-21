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
  %{"email" => "adam@gmail.com", "password" => "password1234"},
  %{"email" => "adam1@gmail.com", "password" => "password1234"},
  %{"email" => "adam2@gmail.com", "password" => "password1234"},
  %{"email" => "adam3@gmail.com", "password" => "password1234"},
  %{"email" => "adam4@gmail.com", "password" => "password1234"},
  %{"email" => "adam5@gmail.com", "password" => "password1234"},
  %{"email" => "adam6@gmail.com", "password" => "password1234"},
  %{"email" => "adam7@gmail.com", "password" => "password1234"},
  %{"email" => "adam8@gmail.com", "password" => "password1234"},
  %{"email" => "adam9@gmail.com", "password" => "password1234"},
  %{"email" => "adam10@gmail.com", "password" => "password1234"},
  %{"email" => "adam11@gmail.com", "password" => "password1234"},
  %{"email" => "adam12@gmail.com", "password" => "password1234"},
  %{"email" => "bob@gmail.com", "password" => "password1234"}
]

Enum.each(users, fn user_attrs ->
  Chat.Users.register_user(user_attrs)
end)
