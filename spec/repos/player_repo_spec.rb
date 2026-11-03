# frozen_string_literal: true

RSpec.describe Fcmanager::Repos::PlayerRepo, :db do
  it "squad_ids devuelve solo los ids de la plantilla" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    repo = Hanami.app["repos.player_repo"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
    player_id = players.insert(
      name: "En Plantilla",
      age: "25",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    players.insert(
      name: "Fuera De Plantilla",
      age: "27",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: other_id
    )

    ids = repo.squad_ids

    expect(ids).to eq([player_id])
  end
end
