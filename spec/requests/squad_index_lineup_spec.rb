# frozen_string_literal: true

RSpec.describe "Squad index lineup badge", :db, type: :request do
  it "marca con XI solo a los jugadores del once" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    starter_id = players.insert(
      name: "Titular",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    players.insert(
      name: "Suplente",
      age: "22",
      overall: "70",
      role: 1,
      height: "178",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: starter_id, slot: 10)

    get("/squad")

    expect(last_response.body.scan('class="badge-xi"').size).to eq(1)
    expect(last_response.body).to match(%r{Titular</a>\s*<span class="badge-xi">\s*XI})
  end
end
