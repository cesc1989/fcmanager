# frozen_string_literal: true

RSpec.describe "Relación lineup_slots", :db do
  it "expone el hueco como clave y la formación del club como string" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    club_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Portero",
      age: "30",
      overall: "75",
      role: 4,
      height: "190",
      dominant_foot: 0,
      primary_position: 0,
      club_id: club_id
    )

    lineup_slots.insert(club_id: club_id, player_id: player_id, slot: 10)

    expect(lineup_slots.where(club_id: club_id).one[:slot]).to eq("st")
    expect(clubs.by_pk(club_id).one[:formation]).to eq("4-1-4-1")
  end

  it "no deja al mismo jugador en dos huecos" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    club_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Central",
      age: "26",
      overall: "74",
      role: 3,
      height: "186",
      dominant_foot: 0,
      primary_position: 2,
      club_id: club_id
    )
    lineup_slots.insert(club_id: club_id, player_id: player_id, slot: 2)

    expect { lineup_slots.insert(club_id: club_id, player_id: player_id, slot: 3) }
      .to raise_error(Sequel::UniqueConstraintViolation)
  end
end
