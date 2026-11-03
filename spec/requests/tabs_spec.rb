# frozen_string_literal: true

RSpec.describe "Header tabs", :db, type: :request do
  it "marca la pestaña activa según la ruta" do
    clubs = Hanami.app["relations.clubs"]
    clubs.insert(name: "Grimsby Town")

    squad_body = get("/squad").body
    compare_body = get("/compare").body
    formation_body = get("/formation").body

    expect(squad_body).to match(%r{href="/squad"\s+class="tab is-active"})
    expect(squad_body).to match(%r{href="/compare"\s+class="tab"\s*>})
    expect(compare_body).to match(%r{href="/compare"\s+class="tab is-active"})
    expect(compare_body).to match(%r{href="/squad"\s+class="tab"\s*>})
    expect(formation_body).to match(%r{href="/formation"\s+class="tab is-active"})
    expect(squad_body).to match(%r{href="/formation"\s+class="tab"\s*>})
  end
end
