# frozen_string_literal: true

RSpec.describe "Squad release", :db, type: :request do
  it "pasa el jugador al club Agente Libre y redirige a la plantilla" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    free_agent_id = clubs.insert(name: "Agente Libre")
    player_id = players.insert(
      name: "Jugador Liberado",
      age: "25",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    patch("/squad/#{player_id}/release")

    expect(last_response.status).to eq(302)
    expect(last_response.headers["Location"]).to eq("/squad")
    expect(players.by_pk(player_id).one[:club_id]).to eq(free_agent_id)
  end

  it "acepta el _method=patch que envía el form del modal" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    free_agent_id = clubs.insert(name: "Agente Libre")
    player_id = players.insert(
      name: "Jugador Liberado",
      age: "25",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    post("/squad/#{player_id}/release", _method: "patch")

    expect(last_response.status).to eq(302)
    expect(players.by_pk(player_id).one[:club_id]).to eq(free_agent_id)
  end

  it "el jugador liberado ya no aparece en la plantilla" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    clubs.insert(name: "Agente Libre")
    player_id = players.insert(
      name: "Jugador Liberado",
      age: "25",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    players.insert(
      name: "Jugador Que Sigue",
      age: "25",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    patch("/squad/#{player_id}/release")
    get("/squad")

    expect(last_response.body).not_to include("Jugador Liberado")
    expect(last_response.body).to include("Jugador Que Sigue")
  end

  it "redirige a la plantilla si el jugador no existe" do
    clubs = Hanami.app["relations.clubs"]
    clubs.insert(name: "Grimsby Town")
    clubs.insert(name: "Agente Libre")

    patch("/squad/999999/release")

    expect(last_response.status).to eq(302)
    expect(last_response.headers["Location"]).to eq("/squad")
  end

  it "la plantilla muestra el botón Liberar con la URL del jugador y el modal" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Jugador Liberado",
      age: "25",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    get("/squad")

    expect(last_response.body).to include(%(title="Liberar"))
    expect(last_response.body).to include(%(data-url="/squad/#{player_id}/release"))
    expect(last_response.body).to include(%(id="release-dialog"))
  end

  it "al liberar a un jugador del once se borra su hueco" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    clubs.insert(name: "Agente Libre")
    player_id = players.insert(
      name: "Jugador Liberado",
      age: "25",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: player_id, slot: 10)

    patch("/squad/#{player_id}/release")

    expect(lineup_slots.where(player_id: player_id).count).to eq(0)
  end
end
