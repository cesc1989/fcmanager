# frozen_string_literal: true

RSpec.describe "Squad index order", :db, type: :request do
  let(:player_repo) { Hanami.app["repos.player_repo"] }

  def create_player(name, position_value)
    player_repo.create(
      name: name,
      age: "25",
      overall: "80",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: Fcmanager::PlayersCatalog.position_db(position_value)
    )
  end

  it "ordena los jugadores por el orden de posiciones del juego" do
    create_player("Delantero", "DC")
    create_player("Portero", "POR")
    create_player("Central", "DFC")
    create_player("LateralIzq", "DFI")
    create_player("MedioOfensivo", "MCO")

    get "/"

    expect(last_response.status).to eq(200)

    expected_order = %w[Portero LateralIzq Central MedioOfensivo Delantero]
    indices = expected_order.map { |name| last_response.body.index(name) }

    expect(indices).to all(be_a(Integer))
    expect(indices).to eq(indices.sort)
  end
end
