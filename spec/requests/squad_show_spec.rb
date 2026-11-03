# frozen_string_literal: true

RSpec.describe "Squad show", :db, type: :request do
  it "enlaza a Comparar con el jugador en el cuadro A" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Ana",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    get("/squad/#{player_id}")

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include(%(href="/compare?a=#{player_id}"))
  end

  it "un jugador del once muestra su hueco y el botón Quitar del campo" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Ana",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: player_id, slot: 10)

    get("/squad/#{player_id}")

    expect(last_response.body).to include("En el once: DC")
    expect(last_response.body).to include("Quitar del campo")
    expect(last_response.body).to include(%(name="return_to" value="/squad/#{player_id}"))
  end

  it "un jugador fuera del once lo indica y no muestra Quitar del campo" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Ana",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    get("/squad/#{player_id}")

    expect(last_response.body).to include("Fuera del once")
    expect(last_response.body).not_to include("Quitar del campo")
  end
end
