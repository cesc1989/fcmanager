# frozen_string_literal: true

RSpec.describe "Squad index order", :db, type: :request do
  it "ordena los jugadores por el orden de posiciones del juego" do
    clubs = Hanami.app["relations.clubs"]
    grimsby_id = clubs.insert(name: "Grimsby Town")

    create_player("Delantero", "DC", grimsby_id)
    create_player("Portero", "POR", grimsby_id)
    create_player("Central", "DFC", grimsby_id)
    create_player("LateralIzq", "DFI", grimsby_id)
    create_player("MedioOfensivo", "MCO", grimsby_id)

    get("/")

    expect(last_response.status).to eq(200)

    expected_order = %w[Portero LateralIzq Central MedioOfensivo Delantero]
    indices = expected_order.map { |name| last_response.body.index(name) }

    expect(indices).to all(be_a(Integer))
    expect(indices).to eq(indices.sort)
  end

  def create_player(name, position_value, club_id)
    player_repo = Hanami.app["repos.player_repo"]

    player_repo.create(
      name: name,
      age: "25",
      overall: "80",
      role: 0,
      height: "180",
      dominant_foot: 0,
      club_id: club_id,
      primary_position: Fcmanager::PlayersCatalog.position_db(position_value)
    )
  end
end
