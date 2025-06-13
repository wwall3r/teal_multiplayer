defmodule TealMultiplayerWeb.WaitingRoomLive do
  use TealMultiplayerWeb, :live_view
  alias TealMultiplayer.Games

  def mount(%{"game_id" => game_id}, session, socket) do
    session_id = session["session_id"]
    
    case Games.get_game_with_players(game_id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/")}
      
      game ->
        # Subscribe to game updates
        Phoenix.PubSub.subscribe(TealMultiplayer.PubSub, "game:#{game_id}")
        
        current_player = Games.get_player_by_session(session_id, game.id)
        
        # If player doesn't exist, automatically add them to the game
        current_player = 
          case current_player do
            nil ->
              # Generate a default name for the player
              player_name = "Player #{length(game.players) + 1}"
              case Games.join_game(game_id, player_name, session_id) do
                {:ok, new_player} -> new_player
                {:error, _} -> nil
              end
            existing_player -> existing_player
          end
        
        # Get updated game data to reflect any new player
        updated_game = Games.get_game_with_players(game_id)
        
        # Identify the game creator (first player who joined)
        creator = updated_game.players |> Enum.min_by(& &1.joined_at)
        is_creator = current_player && current_player.id == creator.id
        
        socket = 
          socket
          |> assign(:game, updated_game)
          |> assign(:current_player, current_player)
          |> assign(:session_id, session_id)
          |> assign(:editing_name, false)
          |> assign(:new_name, current_player && current_player.name || "")
          |> assign(:is_creator, is_creator)
        
        {:ok, socket}
    end
  end

  def handle_event("edit_name", _params, socket) do
    {:noreply, assign(socket, :editing_name, true)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, 
     socket
     |> assign(:editing_name, false)
     |> assign(:new_name, socket.assigns.current_player.name)
    }
  end

  def handle_event("start_game", _params, socket) do
    if socket.assigns.is_creator do
      case Games.start_game(socket.assigns.game.game_id) do
        {:ok, _game} ->
          # Broadcast game started to all players
          Phoenix.PubSub.broadcast(TealMultiplayer.PubSub, "game:#{socket.assigns.game.game_id}", 
            {:game_started})
          
          {:noreply, socket |> put_flash(:info, "Game started!")}
        
        {:error, _reason} ->
          {:noreply, socket |> put_flash(:error, "Failed to start game")}
      end
    else
      {:noreply, socket |> put_flash(:error, "Only the game creator can start the game")}
    end
  end

  def handle_event("update_name", %{"name" => name}, socket) do
    case Games.update_player_name(socket.assigns.session_id, socket.assigns.game.id, name) do
      {:ok, updated_player} ->
        # Broadcast the update to all players in this game
        Phoenix.PubSub.broadcast(TealMultiplayer.PubSub, "game:#{socket.assigns.game.game_id}", 
          {:player_updated, updated_player})
        
        {:noreply, 
         socket
         |> assign(:current_player, updated_player)
         |> assign(:editing_name, false)
         |> assign(:new_name, name)
        }
      
      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update name")
         |> assign(:editing_name, false)
        }
    end
  end

  def handle_info({:player_updated, _updated_player}, socket) do
    # Refresh the game data when any player updates
    updated_game = Games.get_game_with_players(socket.assigns.game.game_id)
    {:noreply, assign(socket, :game, updated_game)}
  end

  def handle_info({:player_joined, _new_player}, socket) do
    # Refresh the game data when a new player joins
    updated_game = Games.get_game_with_players(socket.assigns.game.game_id)
    {:noreply, assign(socket, :game, updated_game)}
  end

  def handle_info({:game_started}, socket) do
    # Handle game start event - could redirect to game view
    {:noreply, socket |> put_flash(:info, "Game has started!")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md mx-auto">
        <div class="text-center">
          <h1 class="text-3xl font-extrabold text-gray-900">Waiting Room</h1>
          <p class="mt-2 text-sm text-gray-600">
            Game ID: <span class="font-mono font-semibold"><%= @game.game_id %></span>
          </p>
        </div>

        <div class="mt-8 bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
              Players (<%= length(@game.players) %>)
            </h3>
            
            <div class="space-y-3">
              <%= for player <- @game.players do %>
                <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div class="flex items-center">
                    <div class="h-8 w-8 bg-blue-500 rounded-full flex items-center justify-center">
                      <span class="text-white font-semibold text-sm">
                        <%= String.first(player.name) |> String.upcase() %>
                      </span>
                    </div>
                    <div class="ml-3">
                      <%= if @current_player && player.id == @current_player.id && @editing_name do %>
                        <form phx-submit="update_name" class="flex items-center space-x-2">
                          <input
                            type="text"
                            name="name"
                            value={@new_name}
                            class="border border-gray-300 rounded px-2 py-1 text-sm"
                            placeholder="Enter your name"
                            required
                          />
                          <button
                            type="submit"
                            class="text-xs bg-blue-600 text-white px-2 py-1 rounded hover:bg-blue-700"
                          >
                            Save
                          </button>
                          <button
                            type="button"
                            phx-click="cancel_edit"
                            class="text-xs bg-gray-300 text-gray-700 px-2 py-1 rounded hover:bg-gray-400"
                          >
                            Cancel
                          </button>
                        </form>
                      <% else %>
                        <p class="text-sm font-medium text-gray-900">
                          <%= player.name %>
                          <%= if @current_player && player.id == @current_player.id do %>
                            <span class="text-xs text-blue-600">(You)</span>
                          <% end %>
                        </p>
                        <p class="text-xs text-gray-500">
                          Joined <%= Calendar.strftime(player.joined_at, "%H:%M") %>
                        </p>
                      <% end %>
                    </div>
                  </div>
                  
                  <%= if @current_player && player.id == @current_player.id && !@editing_name do %>
                    <button
                      phx-click="edit_name"
                      class="text-xs text-blue-600 hover:text-blue-800"
                    >
                      Edit name
                    </button>
                  <% end %>
                </div>
              <% end %>
            </div>

            <div class="mt-6 pt-4 border-t border-gray-200">
              <%= if @is_creator do %>
                <div class="flex flex-col items-center space-y-4">
                  <button
                    phx-click="start_game"
                    class="w-full bg-green-600 text-white px-4 py-2 rounded-lg font-semibold hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                  >
                    Start Game
                  </button>
                  <p class="text-sm text-gray-500 text-center">
                    Share the Game ID with others to let them join!
                  </p>
                </div>
              <% else %>
                <p class="text-sm text-gray-500 text-center">
                  Waiting for the game creator to start the game...
                </p>
              <% end %>
            </div>
          </div>
        </div>

        <div class="mt-6 text-center">
          <a
            href={~p"/"}
            class="text-sm text-blue-600 hover:text-blue-800"
          >
            ← Back to Home
          </a>
        </div>
      </div>
    </div>
    """
  end
end