Example::Application.routes.draw do
  match "/pads/share" => "pads#share"
  match "/pads/:id" => "pads#show"

  match "/documents/share" => "documents#share"
  match "/documents/:id" => "documents#show"
end
