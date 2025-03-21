defmodule ChatWeb.HomeLive do
  use ChatWeb, :live_view
  alias Chat.Rooms
  alias Chat.Rooms.Room
  alias Chat.UserRooms

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Chat.Rooms.subscribe()
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
      <div class="flex flex-col bg-[#f2f3f5] text-lg text-[#69737F]">
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
      </div>
      
      <div class="flex flex-1 items-center justify-center">
        <p class="text-center px-4 text-2xl">
          Select a room on the left to view its messages or create a new room.
        </p>
      </div>
    </div>
    """
  end

  def handle_info({:room_created, room}, socket) do
    if UserRooms.user_room_exist(%{
         "user_id" => socket.assigns.current_user.id,
         "room_id" => room.id
       }) do
      {:noreply, stream_insert(socket, :rooms, room)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate_room", %{"room" => room_params}, socket) do
    changeset = Rooms.change_room(%Room{}, room_params)

    {:noreply,
     socket
     |> assign(:room_form, to_form(changeset, action: :validate))}
  end

  def handle_event("save_room", %{"room" => room_params}, socket) do
    room_params = Map.put(room_params, "user_id", socket.assigns.current_user.id)

    case Rooms.create_room(room_params) do
      {:ok, room, _message} ->
        {:noreply,
         socket
         |> assign(:room_form, to_form(Rooms.change_room(%Room{})))
         |> put_flash(:info, "Room #{room.name} created")}

      {:error, changeset} ->
        {:noreply, socket |> assign(:form, to_form(changeset))}
    end
  end
end
