defmodule ChatWeb.HomeLive do
  use ChatWeb, :live_view
  alias Chat.Rooms
  alias Chat.Rooms.Room

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if connected?(socket) do
      Chat.UserRooms.subscribe({:user_id, current_user.id})
    end

    room_changeset = Rooms.change_room(%Room{})

    {:ok,
     socket
     |> stream(:rooms, Rooms.list_rooms_of_user(socket.assigns.current_user.id))
     |> assign(:room_form, to_form(room_changeset))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-x-hidden">
      <div class="flex flex-col w-64 bg-[#f2f3f5] text-lg text-[#69737F]">
        <div class="flex border-b-2 border-gray-300 justify-between items-center p-1 px-2">
          <h1 class="text-2xl font-semibold ">Rooms</h1>
          
          <div class="relative group">
            <button
              phx-click={show_modal("create-room-modal")}
              class="text-4xl pb-1 text-[#8d8f92] hover:text-[#a9abafcb] group"
            >
              +
              <div class="absolute left-1/2 transform
                       -translate-x-1/2 z-20  w-max px-2 py-1
                       text-sm text-white bg-gray-700 rounded
                       shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-100 pointer-events-none">
                Add new room
              </div>
            </button>
          </div>
        </div>
        
        <div
          id="rooms"
          class="flex-1 flex flex-col w-64 overflow-y-auto overflow-x-hidden gap-1 p-2"
          phx-update="stream"
        >
          <.link
            :for={{dom_id, room} <- @streams.rooms}
            class="flex items-center gap-2 hover:bg-[#e5e8ec]  w-full p-2 rounded hover:text-black"
            navigate={~p"/chat/#{room.id}"}
            id={dom_id}
          >
            <span class="font-semibold text-gray-500 text-2xl">#</span>
            <p class="truncate">{room.name}</p>
          </.link>
        </div>
        
        <div class="border-t-2 p-2 border-gray-400">
          <div class="flex items-center gap-2">
            <img
              src={@current_user.profile_image}
              class="h-10 w-10 border border-gray-400 rounded-full"
              alt="pokemon"
            />
            <p class="font-medium text-base text-black break-all">
              {@current_user.email}
            </p>
          </div>
          
          <.link
            href={~p"/users/settings"}
            class="bg-gray-700 block text-white w-full text-center hover:bg-gray-800 text-sm rounded mb-2 mt-4 p-2 px-2 mr-2"
          >
            Settings
          </.link>
          
          <.link
            href={~p"/users/log_out"}
            method="delete"
            class="bg-gray-700 block text-white w-full text-center hover:bg-gray-800 text-sm rounded p-2 px-2 mr-2"
          >
            Log out
          </.link>
        </div>
      </div>
      
      <div class="flex flex-1 items-center justify-center">
        <p class="text-center px-4 text-2xl">
          Select a room on the left to view its messages or create a new room.
        </p>
      </div>
      
      <.modal id="create-room-modal">
        <.form for={@room_form} phx-submit="save_room" phx-change="validate_room">
          <.input label="Room name" field={@room_form[:name]} />
          <div class="flex mt-8">
            <button class="ml-auto p-2 rounded bg-gray-700 hover:bg-gray-900 text-white" type="submit">
              Create Room
            </button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  def handle_info({:user_added_room, room_id}, socket) do
    room = Rooms.get_room!(room_id)

    {:noreply,
     socket
     |> stream_insert(:rooms, room)
     |> put_flash(:info, "You have been added to room #{room.name}")}
  end

  def handle_event("validate_room", %{"room" => room_params}, socket) do
    changeset = Rooms.change_room(%Room{}, room_params)

    {:noreply,
     socket
     |> assign(:room_form, to_form(changeset, action: :validate))}
  end

  def handle_event("save_room", %{"room" => room_params}, socket) do
    IO.inspect(room_params, label: "here")
    room_params = Map.put(room_params, "user_id", socket.assigns.current_user.id)

    case Rooms.create_room(room_params) do
      {:ok, room, _message} ->
        {:noreply,
         socket
         |> assign(:room_form, to_form(Rooms.change_room(%Room{})))
         |> stream_insert(:rooms, room)
         |> push_navigate(to: ~p"/chat/#{room.id}")
         |> put_flash(:info, "Room #{room.name} created")}

      {:error, changeset} ->
        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end
end
