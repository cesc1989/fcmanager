# frozen_string_literal: true

RSpec.describe "Root", :db, type: :request do
  it "renders the squad list" do
    clubs = Hanami.app["relations.clubs"]
    clubs.insert(name: "Grimsby Town")

    get("/")

    expect(last_response.status).to be(200)
  end
end
