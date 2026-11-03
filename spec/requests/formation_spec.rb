# frozen_string_literal: true

RSpec.describe "Formation", :db, type: :request do
  it "lista la plantilla, pinta los 11 huecos vacíos y los chips" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
    players.insert(
      name: "Theo Marchal",
      age: "27",
      overall: "83",
      role: 4,
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

    get("/formation")

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Theo Marchal")
    expect(last_response.body).not_to include("Fuera De Plantilla")
    expect(last_response.body).to include("1-4-1-4-1")
    expect(last_response.body.scan('data-slot="').size).to eq(11)
    expect(last_response.body).to match(%r{0/11 alineados})
    expect(last_response.body).not_to include("Media")
  end

  it "muestra a los alineados en su hueco, con insignia, encaje y media" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    striker_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    winger_id = players.insert(
      name: "Eva Extremo",
      age: "22",
      overall: "71",
      role: 2,
      height: "170",
      dominant_foot: 1,
      primary_position: 11,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: striker_id, slot: 10)
    lineup_slots.insert(club_id: grimsby_id, player_id: winger_id, slot: 0)

    get("/formation")

    expect(last_response.body).to match(%r{2/11 alineados})
    expect(last_response.body).to include("Media 76")
    expect(last_response.body).to include(%(href="/squad/#{striker_id}"))
    expect(last_response.body).to include(%(class="token is-mid fit-off"))
    expect(last_response.body).to include(%(class="token is-elite"))
    expect(last_response.body).to include("Eva Extremo juega de Extremo izquierdo, hueco de Portero")
    expect(last_response.body).to match(%r{class="badge-xi">\s*POR\s*</span>})
  end

  it "con ?sel= marca al jugador y los huecos envían assign" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
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

    get("/formation", sel: player_id.to_s)

    # El jugador seleccionado enlaza a /formation para deseleccionarlo.
    expect(last_response.body).to match(%r{href="/formation"\s+class="bench-item is-selected"})
    expect(last_response.body.scan('class="slot-target"').size).to eq(11)
    expect(last_response.body).to include(%(name="player_id" value="#{player_id}"))
  end

  it "ignora un ?sel= basura o ajeno" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
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

    bodies = ["abc", "", outsider_id.to_s].map { |sel| get("/formation", sel: sel).body }

    expect(bodies).to all(satisfy { |body| !body.include?("slot-target") })
  end
end
