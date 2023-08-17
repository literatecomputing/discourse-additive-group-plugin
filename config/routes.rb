# frozen_string_literal: true

AdditiveGroupModule::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::AdditiveGroupModule::Engine, at: "my-plugin" }
