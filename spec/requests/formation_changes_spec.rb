# frozen_string_literal: true

RSpec.describe "Formation changes", :db, type: :request do
  it "assign coloca a un jugador de la lista y redirige" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    post("/formation/assign", slot: "st", player_id: player_id.to_s)

    expect(last_response.status).to eq(302)
    expect(last_response.headers["Location"]).to eq("/formation")
    expect(lineup_slots.where(club_id: grimsby_id).one[:slot]).to eq("st")
  end

  it "assign intercambia dos jugadores del campo" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    left_id = players.insert(
      name: "Central Izq",
      age: "26",
      overall: "74",
      role: 3,
      height: "186",
      dominant_foot: 1,
      primary_position: 2,
      club_id: grimsby_id
    )
    right_id = players.insert(
      name: "Central Der",
      age: "27",
      overall: "75",
      role: 3,
      height: "188",
      dominant_foot: 0,
      primary_position: 2,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: left_id, slot: 2)
    lineup_slots.insert(club_id: grimsby_id, player_id: right_id, slot: 3)

    post("/formation/assign", slot: "cbr", player_id: left_id.to_s)

    saved = lineup_slots.where(club_id: grimsby_id).to_a.to_h { |row| [row[:slot], row[:player_id]] }

    expect(saved).to eq("cbl" => right_id, "cbr" => left_id)
  end

  it "assign ignora ids basura, ajenos y huecos inexistentes" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
    player_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    outsider_id = players.insert(
      name: "Fuera De Plantilla",
      age: "27",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: other_id
    )

    post("/formation/assign", slot: "st", player_id: "abc")
    post("/formation/assign", slot: "st", player_id: "")
    post("/formation/assign", slot: "st", player_id: outsider_id.to_s)
    post("/formation/assign", slot: "zz", player_id: player_id.to_s)
    post("/formation/assign", player_id: player_id.to_s)

    expect(last_response.status).to eq(302)
    expect(lineup_slots.where(club_id: grimsby_id).count).to eq(0)
  end

  it "bench saca al jugador y vuelve a la ficha solo si return_to es una ficha" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: player_id, slot: 10)

    post("/formation/bench", player_id: player_id.to_s, return_to: "/squad/#{player_id}")
    to_player = last_response.headers["Location"]
    post("/formation/bench", player_id: player_id.to_s, return_to: "https://evil.example/squad/1")
    to_formation = last_response.headers["Location"]

    expect(lineup_slots.where(club_id: grimsby_id).count).to eq(0)
    expect(to_player).to eq("/squad/#{player_id}")
    expect(to_formation).to eq("/formation")
  end

  it "auto rellena el once y clear lo vacía" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    keeper_id = players.insert(
      name: "Portero",
      age: "30",
      overall: "75",
      role: 4,
      height: "190",
      dominant_foot: 0,
      primary_position: 0,
      club_id: grimsby_id
    )
    striker_id = players.insert(
      name: "Delantero",
      age: "24",
      overall: "80",
      role: 4,
      height: "182",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    post("/formation/auto")
    after_auto = lineup_slots.where(club_id: grimsby_id).to_a.to_h { |row| [row[:slot], row[:player_id]] }
    post("/formation/clear")

    expect(after_auto).to eq("gk" => keeper_id, "st" => striker_id)
    expect(lineup_slots.where(club_id: grimsby_id).count).to eq(0)
    expect(last_response.headers["Location"]).to eq("/formation")
  end
end
