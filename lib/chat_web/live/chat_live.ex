defmodule ChatWeb.ChatLive do
  use ChatWeb, :live_view
  alias Chat.Messages
  alias Chat.Messages.Message
  alias Chat.Rooms
  alias Chat.Rooms.Room
  alias Chat.UserRooms
  alias Chat.Users

  on_mount {ChatWeb.UserAuth, :ensure_is_member}

  @join_room_message "has joined the room."
  @leave_room_message "has left the room."

  def mount(params, _session, socket) do
    %{"room_id" => room_id} = params
    current_user = socket.assigns.current_user

    if connected?(socket) do
      Chat.UserRooms.subscribe({:user_id, current_user.id})
      Chat.UserRooms.subscribe({:room_id, room_id})
      Chat.Messages.subscribe(room_id)
    end

    message_changeset = Messages.change_message(%Message{})

    room_changeset = Rooms.change_room(%Room{})

    now = DateTime.utc_now()
    messages = Messages.get_messages_from_room(room_id, now, 100) |> Enum.reverse()

    {:ok,
     socket
     |> stream(:rooms, Rooms.list_rooms_of_user(current_user.id))
     |> stream(:messages, messages)
     |> stream(:current_room_users, UserRooms.get_users_in_room(room_id))
     |> assign(:earliest_message, List.first(messages))
     |> assign(:current_room, Rooms.get_room!(room_id))
     |> assign(:message_form, to_form(message_changeset))
     |> assign(:room_form, to_form(room_changeset))
     |> assign(:invite_users_form, to_form(%{"selected_users" => [], "search" => ""}))
     |> assign(:join_room_message, @join_room_message)
     |> assign(:leave_room_message, @leave_room_message)
     |> stream(:filtered_users, [], reset: true)}
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

  def format_inserted_at_date_only(inserted_at) do
    inserted_at
    |> Timex.Timezone.convert("Asia/Singapore")
    |> Timex.format!("%d %B %Y", :strftime)
  end

  # phx-hook="SidebarResize"
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-x-hidden">
      <div class="hidden sm:flex flex-col sm:w-64 bg-[#f2f3f5] text-lg text-[#69737F]">
        <div class="flex border-b-2 border-gray-300 justify-between items-center p-1 px-2">
          <h1 class="text-2xl font-semibold">Rooms</h1>
          
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
      
      <div class="sm:hidden z-30">
        <input type="checkbox" id="mobile-sidebar-toggle" class="hidden peer" />
        <div class="fixed inset-0 top-0 bg-black bg-opacity-50 left-0 hidden peer-checked:block">
          <label for="mobile-sidebar-toggle" class="absolute inset-0"></label>
          <div class="h-full flex-col flex absolute left-0 top-0 w-64 bg-[#f2f3f5] text-lg text-[#69737F]">
            <div class="flex border-b-2 border-gray-300 justify-between items-center p-1 px-2">
              <h1 class="text-2xl font-semibold">Rooms</h1>
              
              <div class="relative group">
                <button
                  phx-click={show_modal("create-room-modal")}
                  class="text-4xl pb-1 text-[#8d8f92] hover:text-[#a9abafcb] group"
                >
                  +
                  <div class="absolute left-1/2 transform
                       -translate-x-1/2 z-50  w-max px-2 py-1
                       text-sm text-white bg-gray-700 rounded
                       shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-100 pointer-events-none">
                    Add new room
                  </div>
                </button>
              </div>
            </div>
            
            <div
              id="mobile-rooms"
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
                id={"mobile-#{dom_id}"}
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
        </div>
      </div>
      
      <div class="w-full flex flex-col overflow-x-hidden">
        <div class="flex z-10 bg-white w-full items-center justify-between pl-6 pt-[9px] pb-[7px] border-b-2 border-gray-300">
          <div class="flex w-full items-center gap-2">
            <label
              for="mobile-sidebar-toggle"
              class="font-bold cursor-pointer sm:hidden text-xl text-gray-400 hover:text-gray-600 pr-2"
            >
              ☰
            </label>
             <span class="text-3xl text-gray-500 font-semibold">#</span>
            <span class="text-2xl font-semibold pb-1 truncate flex-grow">{@current_room.name}</span>
            <button phx-click={show_modal("room-info-modal")}>
              <svg
                class="w-5 h-5 hover:fill-gray-500"
                version="1.1"
                xmlns="http://www.w3.org/2000/svg"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                viewBox="0 0 416.979 416.979"
                xml:space="preserve"
              >
                <g>
                  <path d="M356.004,61.156c-81.37-81.47-213.377-81.551-294.848-0.182c-81.47,81.371-81.552,213.379-0.181,294.85
    c81.369,81.47,213.378,81.551,294.849,0.181C437.293,274.636,437.375,142.626,356.004,61.156z M237.6,340.786
    c0,3.217-2.607,5.822-5.822,5.822h-46.576c-3.215,0-5.822-2.605-5.822-5.822V167.885c0-3.217,2.607-5.822,5.822-5.822h46.576
    c3.215,0,5.822,2.604,5.822,5.822V340.786z M208.49,137.901c-18.618,0-33.766-15.146-33.766-33.765
    c0-18.617,15.147-33.766,33.766-33.766c18.619,0,33.766,15.148,33.766,33.766C242.256,122.755,227.107,137.901,208.49,137.901z" />
                </g>
              </svg>
            </button>
            
            <button
              phx-click={show_modal("add-members-modal")}
              class="flex-shrink-0 ml-auto bg-gray-700 text-white hover:bg-gray-800 text-sm rounded p-1 px-2 mr-2"
            >
              + Add
            </button>
          </div>
        </div>
        
        <.modal id="room-info-modal">
          <p class="text-lg font-semibold">Members:</p>
          
          <div id="current_room_users" class="border max-h-80 overflow-y-auto" phx-update="stream">
            <p :for={{dom_id, current_room_user} <- @streams.current_room_users} id={dom_id}>
              {current_room_user.email}
              <span :if={current_room_user.id == @current_user.id} class="font-bold">
                (you)
              </span>
            </p>
          </div>
          
          <div class="flex justify-end">
            <button
              phx-click="leave_room"
              class="bg-red-600 mt-8 text-white hover:bg-red-700 text-sm rounded p-1 px-2"
            >
              Leave room
            </button>
          </div>
        </.modal>
        
        <.modal id="add-members-modal">
          <div class="flex gap-2 mb-3 flex-wrap">
            <div
              :for={selected_user <- @invite_users_form.params["selected_users"]}
              class="bg-gray-200 p-1 pl-2 text-sm rounded-full inline-flex gap-1 items-center"
            >
              <p>
                {selected_user.email}
              </p>
              
              <button
                phx-value-id={selected_user.id}
                phx-click="remove_selected_user"
                class="rounded-full font-bold group text-lg hover:bg-gray-100 p-2 bg-gray-50"
              >
                <svg
                  class="h-[10px] w-[10px] fill-gray-400 group-hover:fill-black"
                  version="1.1"
                  xmlns="http://www.w3.org/2000/svg"
                  xmlns:xlink="http://www.w3.org/1999/xlink"
                  viewBox="0 0 460.775 460.775"
                  xml:space="preserve"
                >
                  <path d="M285.08,230.397L456.218,59.27c6.076-6.077,6.076-15.911,0-21.986L423.511,4.565c-2.913-2.911-6.866-4.55-10.992-4.55
    c-4.127,0-8.08,1.639-10.993,4.55l-171.138,171.14L59.25,4.565c-2.913-2.911-6.866-4.55-10.993-4.55
    c-4.126,0-8.08,1.639-10.992,4.55L4.558,37.284c-6.077,6.075-6.077,15.909,0,21.986l171.138,171.128L4.575,401.505
    c-6.074,6.077-6.074,15.911,0,21.986l32.709,32.719c2.911,2.911,6.865,4.55,10.992,4.55c4.127,0,8.08-1.639,10.994-4.55
    l171.117-171.12l171.118,171.12c2.913,2.911,6.866,4.55,10.993,4.55c4.128,0,8.081-1.639,10.992-4.55l32.709-32.719
    c6.074-6.075,6.074-15.909,0-21.986L285.08,230.397z" />
                </svg>
              </button>
            </div>
          </div>
          
          <.form
            phx-submit="add_members"
            class="relative"
            for={@invite_users_form}
            phx-change="filter_users"
          >
            <.input
              type="text"
              list="filtered-users-list"
              field={@invite_users_form[:search]}
              placeholder="Enter user here..."
              autocomplete="off"
              phx-debounce="200"
              input_class="rounded-b-none"
            />
            <ul
              :if={
                length(@streams.filtered_users.inserts) == 0 &&
                  @invite_users_form.params["search"] != ""
              }
              class="max-h-60 w-full border border-t-0 border-gray-300 absolute bg-white overflow-y-auto text-sm text-gray-700"
            >
              <li>
                No users found
              </li>
            </ul>
            
            <ul
              :if={length(@streams.filtered_users.inserts) > 0}
              class="max-h-60 w-full border border-t-0 border-gray-300 absolute bg-white overflow-y-auto text-sm text-gray-700"
            >
              <li
                :for={{dom_id, filtered_user} <- @streams.filtered_users}
                id={dom_id}
                phx-click="select_user"
                phx-value-id={filtered_user.id}
                class="py-2 w-full cursor-pointer hover:bg-indigo-100"
              >
                {filtered_user.email}
              </li>
            </ul>
            
            <div class="flex mt-8">
              <button
                class="ml-auto p-2 rounded bg-gray-700 disabled:cursor-not-allowed disabled:bg-gray-200 hover:bg-gray-900 text-white"
                type="submit"
                disabled={length(@invite_users_form.params["selected_users"] || []) == 0}
              >
                Add members
              </button>
            </div>
          </.form>
        </.modal>
        
        <div
          id="messages-div"
          phx-hook="ScrollToBottomAndLoadMore"
          class="-mt-5 pb-4 flex-1 overflow-y-auto"
          phx-update="stream"
        >
          <div :for={{dom_id, message} <- @streams.messages} class="group" id={dom_id}>
            <div
              :if={message.is_new_day}
              class="text-xs font-bold mt-8 -mb-2 text-gray-500 text-center"
            >
              <div class="flex items-center justify-center space-x-2">
                <span class="flex-1 border-t border-gray-300"></span>
                <span class="text-center font-semibold">
                  {format_inserted_at_date_only(message.inserted_at)}
                </span>
                 <span class="flex-1 border-t border-gray-300"></span>
              </div>
            </div>
            
            <div :if={message.is_action} class="gap-2 pl-3 flex mt-6">
              <svg
                :if={message.content == @leave_room_message}
                class="w-8 h-8 flex-shrink-0 fill-red-500"
                version="1.1"
                xmlns="http://www.w3.org/2000/svg"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                viewBox="0 0 476.213 476.213"
                xml:space="preserve"
              >
                <polygon points="476.213,223.107 57.427,223.107 151.82,128.713 130.607,107.5 0,238.106 130.607,368.714 151.82,347.5
    57.427,253.107 476.213,253.107 " />
              </svg>
              
              <svg
                :if={message.content == @join_room_message}
                class="w-8 h-8 flex-shrink-0 fill-green-500"
                version="1.1"
                xmlns="http://www.w3.org/2000/svg"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                viewBox="0 0 476.213 476.213"
                xml:space="preserve"
                transform="matrix(-1, 0, 0, 1, 0, 0)"
              >
                <g stroke-width="0"></g>
                
                <g stroke-linecap="round" stroke-linejoin="round"></g>
                
                <g>
                  <polygon points="476.213,223.107 57.427,223.107 151.82,128.713 130.607,107.5 0,238.106 130.607,368.714 151.82,347.5 57.427,253.107 476.213,253.107 ">
                  </polygon>
                </g>
              </svg>
              
              <div class="relative">
                <p class="break-words pl-3 pt-[2px]">
                  <span class="font-bold">{message.user.email}</span> <span>{message.content}</span>
                  <span class="text-xs font-normal select-none text-gray-500">
                    {format_inserted_at_full(message.inserted_at)}
                  </span>
                </p>
              </div>
            </div>
            
            <div :if={message.is_start_of_sequence} class="mt-6 pl-16 relative">
              <div class="w-11 absolute left-2 top-1 h-11 -z-10 rounded-full border flex items-center justify-center ">
                <img src={message.user.profile_image} class="h-10 w-10" alt="pokemon" />
              </div>
              
              <p class="font-bold">
                {message.user.email}
                <span class="text-xs font-normal select-none text-gray-500">
                  {format_inserted_at_full(message.inserted_at)}
                </span>
              </p>
            </div>
            
            <div :if={!message.is_action} class="relative">
              <p class="break-words pl-16">
                {message.content}
              </p>
              
              <p
                :if={!message.is_start_of_sequence}
                class="invisible group group-hover:visible absolute top-1 right-full translate-x-[52px] text-xs font-normal whitespace-nowrap text-gray-500 pointer-events-none select-none"
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
            autocomplete="off"
          />
          <button type="submit" class="self-start pt-1">
            <svg
              class="w-8 h-8 fill-gray-600 hover:fill-gray-300"
              viewBox="0 0 28 28"
              version="1.1"
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
            >
              <g stroke-width="1" fill-rule="evenodd">
                <g fill-rule="nonzero">
                  <path d="M3.78963301,2.77233335 L24.8609339,12.8499121 C25.4837277,13.1477699 25.7471402,13.8941055 25.4492823,14.5168992 C25.326107,14.7744476 25.1184823,14.9820723 24.8609339,15.1052476 L3.78963301,25.1828263 C3.16683929,25.4806842 2.42050372,25.2172716 2.12264586,24.5944779 C1.99321184,24.3238431 1.96542524,24.015685 2.04435886,23.7262618 L4.15190935,15.9983421 C4.204709,15.8047375 4.36814355,15.6614577 4.56699265,15.634447 L14.7775879,14.2474874 C14.8655834,14.2349166 14.938494,14.177091 14.9721837,14.0981464 L14.9897199,14.0353553 C15.0064567,13.9181981 14.9390703,13.8084248 14.8334007,13.7671556 L14.7775879,13.7525126 L4.57894108,12.3655968 C4.38011873,12.3385589 4.21671819,12.1952832 4.16392965,12.0016992 L2.04435886,4.22889788 C1.8627142,3.56286745 2.25538645,2.87569101 2.92141688,2.69404635 C3.21084015,2.61511273 3.51899823,2.64289932 3.78963301,2.77233335 Z">
                  </path>
                </g>
              </g>
            </svg>
          </button>
        </.form>
        
        <.modal id="create-room-modal">
          <.form for={@room_form} phx-submit="save_room" phx-change="validate_room">
            <.input label="Room name" field={@room_form[:name]} />
            <div class="flex mt-8">
              <button
                class="ml-auto p-2 rounded bg-gray-700 hover:bg-gray-900 text-white"
                type="submit"
              >
                Create Room
              </button>
            </div>
          </.form>
        </.modal>
      </div>
    </div>
    """
  end

  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info({:room_added_user, user_id, message} = params, socket) do
    user = Users.get_user!(user_id)

    {:noreply,
     socket
     |> stream_insert(:messages, message, at: -1)
     |> stream_insert(:current_room_users, user, at: -1)}
  end

  def handle_info({:user_added_room, room_id}, socket) do
    room = Rooms.get_room!(room_id)

    {:noreply,
     socket
     |> stream_insert(:rooms, room)
     |> put_flash(:info, "You have been added to room #{room.name}")}
  end

  def handle_info({:room_removed_user, user_id, message}, socket) do
    user = Users.get_user!(user_id)

    {:noreply,
     socket
     |> stream_insert(:messages, message, at: -1)
     |> stream_delete(:current_room_users, user)}
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
      {:ok, room, _message} ->
        {:noreply,
         socket
         |> assign(:room_form, to_form(Rooms.change_room(%Room{})))
         |> stream_insert(:rooms, room)
         |> push_navigate(to: ~p"/chat/#{room.id}")
         |> put_flash(:info, "Room #{room.name} created")}

      {:error, changeset} ->
        {:noreply, assign(socket, :room_form, to_form(changeset))}
    end
  end

  def handle_event("filter_users", %{"search" => search}, socket) do
    updated_filters =
      %{
        "selected_users" => socket.assigns.invite_users_form.params["selected_users"],
        "search" => search
      }

    {:noreply,
     socket
     |> assign(:invite_users_form, to_form(updated_filters))
     |> stream(
       :filtered_users,
       Users.filter_invited_users(updated_filters, socket.assigns.current_room.id),
       reset: true
     )}
  end

  def handle_event("select_user", %{"id" => user_id}, socket) do
    selected_user = Users.get_user!(user_id)

    updated_selected_users =
      socket.assigns.invite_users_form.params["selected_users"] ++ [selected_user]

    updated_form = to_form(%{"selected_users" => updated_selected_users, "search" => ""})

    {:noreply,
     socket
     |> assign(:invite_users_form, updated_form)}
  end

  def handle_event("remove_selected_user", %{"id" => user_id}, socket) do
    user_id = String.to_integer(user_id)

    updated_filters =
      %{
        "selected_users" =>
          Enum.reject(socket.assigns.invite_users_form.params["selected_users"], fn user ->
            user.id == user_id
          end),
        "search" => socket.assigns.invite_users_form.params["search"]
      }

    {:noreply,
     socket
     |> assign(:invite_users_form, to_form(updated_filters))
     |> stream(
       :filtered_users,
       Users.filter_invited_users(updated_filters, socket.assigns.current_user),
       reset: true
     )}
  end

  def handle_event("add_members", _, socket) do
    current_room = socket.assigns.current_room

    selected_users = socket.assigns.invite_users_form.params["selected_users"]
    UserRooms.add_users_to_room(selected_users, current_room.id)

    updated_filters =
      %{
        "selected_users" => [],
        "search" => ""
      }

    {:noreply,
     socket
     |> put_flash(
       :info,
       "Added to room #{current_room.name}!"
     )
     |> assign(:invite_users_form, to_form(updated_filters))
     |> push_event("js-exec", %{to: "#add-members-modal", attr: "data-cancel"})}
  end

  def handle_event("leave_room", _, socket) do
    current_room = socket.assigns.current_room
    current_user = socket.assigns.current_user
    UserRooms.remove_user_from_room(current_user.id, current_room.id)

    {:noreply,
     socket
     |> put_flash(
       :info,
       "Left room #{current_room.name}!"
     )
     |> stream_delete(:rooms, current_room)
     |> push_navigate(to: ~p"/")}
  end

  def handle_event("load-more", _params, socket) do
    current_room = socket.assigns.current_room

    earliest_message = socket.assigns.earliest_message.inserted_at

    messages = Messages.get_messages_from_room(current_room.id, earliest_message, 100)

    if messages == [] do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> stream(:messages, messages, at: 0)
       |> assign(:earliest_message, List.first(messages))
       |> push_event("messages-loaded", %{})}
    end
  end
end
