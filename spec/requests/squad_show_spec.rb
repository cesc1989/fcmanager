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
end
