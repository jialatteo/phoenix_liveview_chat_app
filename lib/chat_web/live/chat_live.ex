defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view
  alias Chat.Messages
  alias Chat.Messages.Message
  alias Chat.Rooms
  alias Chat.Rooms.Room
  alias Chat.UserRooms

  on_mount {ChatWeb.UserAuth, :ensure_is_member}

  def mount(params, _session, socket) do
    %{"room_id" => room_id} = params

    if connected?(socket) do
      Chat.Messages.subscribe(room_id)
      Chat.Rooms.subscribe()
    end

    message_changeset = Messages.change_message(%Message{})

    room_changeset = Rooms.change_room(%Room{})

    {:ok,
     socket
     |> stream(:rooms, Rooms.list_rooms_of_user(socket.assigns.current_user.id))
     |> stream(:messages, Messages.get_messages_from_room(room_id))
     |> assign(:current_room, Rooms.get_room!(room_id))
     |> assign(:message_form, to_form(message_changeset))
     |> assign(:room_form, to_form(room_changeset))}
  end

  def format_inserted_at_full(inserted_at) do
    inserted_at
    |> Timex.Timezone.convert("Asia/Singapore")
    |> Timex.format!("%d/%m/%Y %l:%M %p", :strftime)
    |> String.downcase()
  end

  def format_inserted_at_time_only(inserted_at) do
    inserted_at
    |> Timex.Timezone.convert("Asia/Singapore")
    |> Timex.format!("%l:%M %p", :strftime)
    |> String.downcase()
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-x-hidden">
      <div class="flex flex-col bg-[#f2f3f5] text-lg text-[#69737F]">
        <div class="flex border-b-2 border-gray-300 justify-between items-center p-1 px-2">
          <h1 class="text-2xl font-semibold ">Rooms</h1>
          
          <div class="relative group">
            <button
              phx-click={show_modal("my-modal")}
              class="text-4xl pb-1 text-[#8d8f92] hover:text-[#a9abafcb] group"
            >
              +
              <div class="absolute left-1/2 transform
                       -translate-x-1/2 z-20  w-max px-2 py-1
                       text-sm text-white bg-gray-700 rounded
                       shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-100 pointer-events-none">
                Add new group
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
            class={[
              "flex items-center gap-2 hover:bg-[#e5e8ec]  w-full p-2 rounded hover:text-black",
              room.id == @current_room.id &&
                "pointer-events-none bg-[#D4D7DC] text-black"
            ]}
            navigate={~p"/chat/#{room.id}"}
            id={dom_id}
          >
            <span class="font-semibold text-gray-500 text-2xl">#</span>
            <p class="truncate">{room.name}</p>
          </.link>
        </div>
      </div>
      
      <div class="w-full flex flex-col overflow-x-hidden">
        <div class="flex z-10 bg-white w-full items-center gap-3 pl-6 pt-[9px] pb-[7px] border-b-2 border-gray-300">
          <span class="text-3xl text-gray-500 font-semibold">#</span>
          <span class="text-2xl font-semibold pb-1 truncate">{@current_room.name}</span>
        </div>
        
        <div
          id="messages-div"
          phx-hook="ScrollToBottom"
          class="-mt-5 pb-4 flex-1 overflow-y-auto"
          phx-update="stream"
        >
          <div :for={{dom_id, message} <- @streams.messages} class="pl-16 group" id={dom_id}>
            <div :if={message.is_start_of_sequence} class="mt-6 relative">
              <div class="w-11 absolute -left-14 top-1 h-11 -z-10 rounded-full bg-red-400"></div>
              
              <p class="font-bold">
                {message.user.email}
                <span class="text-xs font-normal select-none text-gray-500">
                  {format_inserted_at_full(message.inserted_at)}
                </span>
              </p>
            </div>
            
            <div class="relative">
              <p class="break-words">
                {message.content}
              </p>
              
              <p
                :if={!message.is_start_of_sequence}
                class="invisible group group-hover:visible absolute top-1 right-full -translate-x-3 text-xs font-normal whitespace-nowrap text-gray-500 pointer-events-none select-none"
              >
                {format_inserted_at_time_only(message.inserted_at)}
              </p>
            </div>
          </div>
        </div>
        
        <.form
          class="px-2 pb-4 bg-white flex gap-2 sticky bottom-0"
          for={@message_form}
          phx-submit="save_message"
          phx-change="validate_message"
        >
          <.input
            class="flex-1"
            placeholder="Write a message..."
            input_class="mt-0 bg-gray-50"
            field={@message_form[:content]}
          />
          <button type="submit" class="self-start pt-1">
            <svg
              class="w-8 h-8 fill-gray-600 hover:fill-gray-300"
              viewBox="0 0 28 28"
              version="1.1"
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
            >
              <g id="🔍-Product-Icons" stroke-width="1" fill-rule="evenodd">
                <g id="ic_fluent_send_28_filled" fill-rule="nonzero">
                  <path
                    d="M3.78963301,2.77233335 L24.8609339,12.8499121 C25.4837277,13.1477699 25.7471402,13.8941055 25.4492823,14.5168992 C25.326107,14.7744476 25.1184823,14.9820723 24.8609339,15.1052476 L3.78963301,25.1828263 C3.16683929,25.4806842 2.42050372,25.2172716 2.12264586,24.5944779 C1.99321184,24.3238431 1.96542524,24.015685 2.04435886,23.7262618 L4.15190935,15.9983421 C4.204709,15.8047375 4.36814355,15.6614577 4.56699265,15.634447 L14.7775879,14.2474874 C14.8655834,14.2349166 14.938494,14.177091 14.9721837,14.0981464 L14.9897199,14.0353553 C15.0064567,13.9181981 14.9390703,13.8084248 14.8334007,13.7671556 L14.7775879,13.7525126 L4.57894108,12.3655968 C4.38011873,12.3385589 4.21671819,12.1952832 4.16392965,12.0016992 L2.04435886,4.22889788 C1.8627142,3.56286745 2.25538645,2.87569101 2.92141688,2.69404635 C3.21084015,2.61511273 3.51899823,2.64289932 3.78963301,2.77233335 Z"
                    id="🎨-Color"
                  >
                  </path>
                </g>
              </g>
            </svg>
          </button>
        </.form>
        
        <.modal id="my-modal">
          <.form for={@room_form} phx-submit="save_room" phx-change="validate_room">
            <.input field={@room_form[:name]} /> <button type="submit">Create Room</button>
          </.form>
        </.modal>
      </div>
    </div>
    """
  end

  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
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

  def handle_event("validate_message", %{"message" => message_params}, socket) do
    changeset = Message.changeset(%Message{}, message_params)

    {:noreply,
     socket
     |> assign(:message_form, to_form(changeset, action: :validate))}
  end

  def handle_event("save_message", %{"message" => message_params}, socket) do
    message_params =
      message_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("room_id", socket.assigns.current_room.id)

    case Messages.create_message(message_params) do
      {:ok, message} ->
        {:noreply,
         socket
         |> assign(:message_form, to_form(Messages.change_message(%Message{})))
         |> stream_insert(:messages, message)
         |> push_event("scroll-to-bottom", %{})}

      {:error, changeset} ->
        {:noreply, assign(socket, message_form: to_form(changeset))}
    end
  end

  def handle_event("validate_room", %{"room" => room_params}, socket) do
    changeset = Room.changeset(%Room{}, room_params)

    {:noreply,
     socket
     |> assign(:room_form, to_form(changeset, action: :validate))}
  end

  def handle_event("save_room", %{"room" => room_params}, socket) do
    room_params = Map.put(room_params, "user_id", socket.assigns.current_user.id)

    case Rooms.create_room(room_params) do
      {:ok, room} ->
        {:noreply,
         socket
         |> assign(:room_form, to_form(Rooms.change_room(%Room{})))
         |> push_navigate(to: ~p"/chat/#{room.id}")
         |> put_flash(:info, "Room #{room.name} created")}

      {:error, changeset} ->
        {:noreply, assign(socket, :room_form, to_form(changeset))}
    end
  end
end
