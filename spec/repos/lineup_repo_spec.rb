# frozen_string_literal: true

RSpec.describe Fcmanager::Repos::LineupRepo, :db do
  it "guarda y vuelve a cargar el once del club" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    repo = Hanami.app["repos.lineup_repo"]
    club_id = clubs.insert(name: "Grimsby Town")
    keeper_id = players.insert(
      name: "Portero",
      age: "30",
      overall: "75",
      role: 4,
      height: "190",
      dominant_foot: 0,
      primary_position: 0,
      club_id: club_id
    )
    striker_id = players.insert(
      name: "Delantero",
      age: "24",
      overall: "80",
      role: 4,
      height: "182",
      dominant_foot: 0,
      primary_position: 12,
      club_id: club_id
    )
    club = clubs.by_pk(club_id).one
    squad_ids = [keeper_id, striker_id]

    repo.change(club, squad_ids) { |lineup| lineup.assign("gk", keeper_id).assign("st", striker_id) }
    repo.change(club, squad_ids) { |lineup| lineup.assign("st", keeper_id) }
    reloaded = repo.for_club(club, squad_ids)

    expect(reloaded.to_h).to eq("gk" => striker_id, "st" => keeper_id)
    expect(reloaded.formation.name).to eq("1-4-1-4-1")
  end

  it "intercambiar dos jugadores del campo no viola el índice único" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    repo = Hanami.app["repos.lineup_repo"]
    club_id = clubs.insert(name: "Grimsby Town")
    left_id = players.insert(
      name: "Central Izq",
      age: "26",
      overall: "74",
      role: 3,
      height: "186",
      dominant_foot: 1,
      primary_position: 2,
      club_id: club_id
    )
    right_id = players.insert(
      name: "Central Der",
      age: "27",
      overall: "75",
      role: 3,
      height: "188",
      dominant_foot: 0,
      primary_position: 2,
      club_id: club_id
    )
    club = clubs.by_pk(club_id).one
    squad_ids = [left_id, right_id]

    repo.change(club, squad_ids) { |lineup| lineup.assign("cbl", left_id).assign("cbr", right_id) }
    repo.change(club, squad_ids) { |lineup| lineup.assign("cbr", left_id) }

    expect(repo.for_club(club, squad_ids).to_h).to eq("cbl" => right_id, "cbr" => left_id)
  end

  it "solo carga el once del club pedido y sin jugadores fuera de la plantilla" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    repo = Hanami.app["repos.lineup_repo"]
    club_id = clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
    keeper_id = players.insert(
      name: "Portero",
      age: "30",
      overall: "75",
      role: 4,
      height: "190",
      dominant_foot: 0,
      primary_position: 0,
      club_id: club_id
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
    lineup_slots.insert(club_id: club_id, player_id: keeper_id, slot: 0)
    lineup_slots.insert(club_id: club_id, player_id: outsider_id, slot: 10)

    lineup = repo.for_club(clubs.by_pk(club_id).one, [keeper_id])

    expect(lineup.to_h).to eq("gk" => keeper_id)
  end
end
