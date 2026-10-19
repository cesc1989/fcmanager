# frozen_string_literal: true

RSpec.describe "Compare", :db, type: :request do
  it "sin params lista la plantilla y pide dos jugadores" do
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

    get("/compare")

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Theo Marchal")
    expect(last_response.body).not_to include("Fuera De Plantilla")
    expect(last_response.body).to include("Carga dos jugadores para ver la comparación.")
  end

  it "compara dos jugadores con traits por kind y arquería solo con portero" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    traits = Hanami.app["relations.traits"]
    player_traits = Hanami.app["relations.player_traits"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    sprint_id = traits.insert(name: "Sprint", kind: 0)
    reflejos_id = traits.insert(name: "Reflejos", kind: 3)
    a_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id,
      comment: "Muy rápida"
    )
    b_id = players.insert(
      name: "Bea Central",
      age: "29",
      overall: "76",
      role: 3,
      height: "182",
      dominant_foot: 0,
      primary_position: 2,
      club_id: grimsby_id
    )
    player_traits.insert(player_id: a_id, trait_id: sprint_id, value: 90)
    player_traits.insert(player_id: b_id, trait_id: sprint_id, value: 70)
    player_traits.insert(player_id: a_id, trait_id: reflejos_id, value: 20)
    player_traits.insert(player_id: b_id, trait_id: reflejos_id, value: 20)

    get("/compare", a: a_id, b: b_id)

    body = last_response.body
    expect(last_response.status).to eq(200)
    expect(body).to include("Ana Delantera gana 1")
    expect(body).to include("FISICOS")
    expect(body).not_to include("ARQUERIA")
    expect(body).to include("◀ +20")
    expect(body).to include("Líneas distintas")
    expect(body).to include("Muy rápida")
    expect(body).to include("Sin comentarios todavía.")
  end

  it "ignora ids basura, ajenos a la plantilla o repetidos" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    free_agent_id = clubs.insert(name: "Agente Libre")
    a_id = players.insert(
      name: "Ana",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    released_id = players.insert(
      name: "Liberado",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: free_agent_id
    )

    responses = [
      get("/compare", a: "abc", b: "999999"),
      get("/compare", a: a_id, b: a_id),
      get("/compare", a: a_id, b: released_id)
    ]

    expect(responses.map(&:status)).to eq([200, 200, 200])
    expect(responses[0].body).to include("Carga dos jugadores para ver la comparación.")
    expect(responses[1].body).to include("Falta un jugador en el cuadro B.")
    expect(responses[2].body).to include("Falta un jugador en el cuadro B.")
  end

  it "los enlaces de la lista y de los cuadros llevan la pareja correcta" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    a_id = players.insert(
      name: "Ana",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    b_id = players.insert(
      name: "Bea",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    get("/compare", a: a_id)

    body = last_response.body
    expect(body).to include(%(href="/compare?a=#{a_id}&amp;b=#{b_id}"))
    expect(body).to include(%(href="/compare?b=#{a_id}"))
    expect(body).to include(%(href="/compare"))
    expect(body).to include(%(data-compare-box="a"))
  end
end
