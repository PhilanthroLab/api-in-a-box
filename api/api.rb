gem 'faraday', '0.8.9' # requirement for stretcher
require "sinatra/base"
require 'stretcher'
require './resource_presenter'

class ApiInABox < Sinatra::Base

  get "/resources" do
    size = params["size"] || "50"
    from = params["from"].to_i
    search = server.index(:api).search(size: size, from: from)
    docs = search.documents
    mappings = server.index(:api).get_mapping["api"]["mappings"]["resource"]["properties"]
    resources = ResourcePresenter.new({resources: docs, queries: mappings}).as_json
    content_type 'application/vnd.collection+json'
    resources.to_json
  end

  get "/resources/search" do
    if params["match_phrase"] == "true"
      params.delete("match_phrase")
      size = params.delete("size") || 50
      from = params.delete("from")
      search = server.index(:api).search(size: size, from: from, query: {match_phrase: params})
    elsif params.present?
      present_params = params.select{|k,v| v.present?}
      query_string = present_params.values.join(", ")
      search = server.index(:api).search(query: {match: present_params})
    else
      search = server.index(:api).search(size: 50)
    end

    docs = search.documents
    mappings = server.index(:api).get_mapping["api"]["mappings"]["resource"]["properties"]
    resources = ResourcePresenter.new({resources: docs, queries: mappings}).as_json
    content_type 'application/vnd.collection+json'
    resources.to_json
  end

  get "/resources/:id" do
    doc = server.index(:api).type(:resource).get(params[:id])
    resources = ResourcePresenter.new({resources: [doc]}).as_json
    content_type 'application/vnd.collection+json'
    resources.to_json
  end

  def host
    ENV["ELASTIC_HOST"] || "http://localhost:9200"
  end

  def server
    @server ||= Stretcher::Server.new(host)
  end
end
