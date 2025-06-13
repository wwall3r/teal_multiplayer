defmodule TealMultiplayerWeb.MultiplayerFlowTest do
  use TealMultiplayerWeb.ConnCase
  import Phoenix.LiveViewTest
  alias TealMultiplayer.Games

  describe "multiplayer game flow" do
    test "user1 creates game, user2 joins via link, both see each other in players list" do
      # Step 1: User1 creates a game
      user1_conn = build_conn()

      # User1 creates a game by posting to create-game endpoint
      user1_conn = post(user1_conn, ~p"/create-game")
      user1_session_id = get_session(user1_conn, :session_id)
      assert redirected_to(user1_conn) =~ "/waiting-room/"
      
      # Extract game_id from redirect path
      redirect_path = redirected_to(user1_conn)
      game_id = redirect_path |> String.split("/") |> List.last()
      refute is_nil(game_id)

      # Step 2: User1 is in the waiting room
      {:ok, user1_view, _html} = live(user1_conn, "/waiting-room/#{game_id}")
      assert render(user1_view) =~ "Players (1)"
      assert render(user1_view) =~ "Start Game"

      # Step 3: User2 joins the game
      user2_conn = build_conn()
      user2_conn = post(user2_conn, ~p"/join-game", %{"game_id" => game_id})
      user2_session_id = get_session(user2_conn, :session_id)
      refute user1_session_id == user2_session_id
      assert redirected_to(user2_conn) == "/waiting-room/" <> game_id

      # Step 4: User2 is now in the waiting room
      {:ok, user2_view, _html} = live(user2_conn, "/waiting-room/#{game_id}")
      assert render(user2_view) =~ "Players (2)"
      refute render(user2_view) =~ "Start Game"

      # Step 5: User1's view should update to show user2
      assert render(user1_view) =~ "Players (2)"

      # Step 6: Verify both users can see each other
      game = Games.get_game_with_players(game_id)
      assert length(game.players) == 2
      
      [player1, player2] = Enum.sort_by(game.players, & &1.joined_at)
      
      user1_html = render(user1_view)
      user2_html = render(user2_view)
      
      assert user1_html =~ player1.name
      assert user1_html =~ player2.name
      assert user2_html =~ player1.name
      assert user2_html =~ player2.name

      # Verify session IDs
      assert player1.session_id == user1_session_id
      assert player2.session_id == user2_session_id

      # Verify UI shows "(You)" markers
      assert user1_html =~ "(You)"
      assert user2_html =~ "(You)"

      # Verify creator privileges
      assert render(user1_view) =~ "Start Game"
      refute render(user2_view) =~ "Start Game"

      # Verify game_id format
      assert String.length(game_id) > 0
      assert game_id =~ ~r/^[A-F0-9]+$/
    end

    test "user2 gets automatic session ID when visiting shared link directly" do
      # User1 creates a game first
      user1_conn = build_conn()
      user1_conn = post(user1_conn, ~p"/create-game")
      redirect_path = redirected_to(user1_conn)
      game_id = redirect_path |> String.split("/") |> List.last()

      # User2 visits the waiting room URL directly (simulating a shared link)
      user2_conn = build_conn()
      
      # Even though they visit the waiting room directly, they should be redirected
      # because they haven't joined the game yet. But they should get a session ID.
      # Let's test by making a request that goes through the session pipeline
      user2_conn = get(user2_conn, "/waiting-room/#{game_id}")
      session_id = get_session(user2_conn, :session_id)
      assert String.length(session_id) > 0
    end

    test "multiple users can join the same game via the shared game_id" do
      # User1 creates a game
      user1_conn = build_conn()
      user1_conn = post(user1_conn, ~p"/create-game")
      redirect_path = redirected_to(user1_conn)
      game_id = redirect_path |> String.split("/") |> List.last()

      # User1 goes to waiting room
      {:ok, user1_view, _html} = live(user1_conn, "/waiting-room/#{game_id}")
      assert render(user1_view) =~ "Players (1)"

      # User2 joins
      user2_conn = build_conn()
      user2_conn = post(user2_conn, ~p"/join-game", %{"game_id" => game_id})
      assert redirected_to(user2_conn) == "/waiting-room/" <> game_id

      # User2 goes to waiting room
      {:ok, user2_view, _html} = live(user2_conn, "/waiting-room/#{game_id}")
      assert render(user2_view) =~ "Players (2)"

      # User3 joins using the same game_id
      user3_conn = build_conn()
      user3_conn = post(user3_conn, ~p"/join-game", %{"game_id" => game_id})
      assert redirected_to(user3_conn) == "/waiting-room/" <> game_id

      # User3 goes to waiting room
      {:ok, user3_view, _html} = live(user3_conn, "/waiting-room/#{game_id}")
      assert render(user3_view) =~ "Players (3)"

      # Verify all three users are in the game
      game = Games.get_game_with_players(game_id)
      assert length(game.players) == 3

      # Verify each user has a unique session ID
      session_ids = Enum.map(game.players, & &1.session_id)
      assert length(Enum.uniq(session_ids)) == 3

      # Get player names ordered by join time
      [player1, player2, player3] = Enum.sort_by(game.players, & &1.joined_at)

      # Verify all players can see each other's names in the players list
      user1_html = render(user1_view)
      user2_html = render(user2_view)
      user3_html = render(user3_view)

      # User1 should see all three players including themselves
      assert user1_html =~ player1.name
      assert user1_html =~ player2.name
      assert user1_html =~ player3.name

      # User2 should see all three players including themselves
      assert user2_html =~ player1.name
      assert user2_html =~ player2.name
      assert user2_html =~ player3.name

      # User3 should see all three players including themselves
      assert user3_html =~ player1.name
      assert user3_html =~ player2.name
      assert user3_html =~ player3.name

      # Verify each user sees the correct player count
      assert user1_html =~ "Players (3)"
      assert user2_html =~ "Players (3)"
      assert user3_html =~ "Players (3)"
    end

    test "player is added to game when landing directly on waiting room URL" do
      # User1 creates a game
      user1_conn = build_conn()
      user1_conn = post(user1_conn, ~p"/create-game")
      redirect_path = redirected_to(user1_conn)
      game_id = redirect_path |> String.split("/") |> List.last()

      # User1 goes to waiting room
      {:ok, user1_view, _html} = live(user1_conn, "/waiting-room/#{game_id}")
      assert render(user1_view) =~ "Players (1)"

      # User2 visits the waiting room URL directly (without going through /join-game)
      user2_conn = build_conn()
      {:ok, user2_view, _html} = live(user2_conn, "/waiting-room/#{game_id}")

      # User2 should be automatically added to the game
      game = Games.get_game_with_players(game_id)
      assert length(game.players) == 2

      # Both users should see 2 players
      assert render(user1_view) =~ "Players (2)"
      assert render(user2_view) =~ "Players (2)"

      # Get player names
      [player1, player2] = Enum.sort_by(game.players, & &1.joined_at)

      # Both users should see each other's names
      user1_html = render(user1_view)
      user2_html = render(user2_view)

      assert user1_html =~ player1.name
      assert user1_html =~ player2.name
      assert user2_html =~ player1.name
      assert user2_html =~ player2.name

      # Verify session IDs are different
      user1_session_id = get_session(user1_conn, :session_id)
      # For user2, we need to get their session ID from the player record since 
      # they accessed the LiveView directly
      user2_session_id = player2.session_id
      refute user1_session_id == user2_session_id
      assert player1.session_id == user1_session_id
      assert player2.session_id == user2_session_id
    end

    test "invalid game_id returns appropriate error" do
      user_conn = build_conn()
      
      # Try to join a non-existent game
      user_conn = post(user_conn, ~p"/join-game", %{"game_id" => "INVALID"})
      assert redirected_to(user_conn) == "/"
      assert Phoenix.Flash.get(user_conn.assigns.flash, :error) == "Game not found"
    end
  end
end