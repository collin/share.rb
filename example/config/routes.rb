Example::Application.routes.draw do
  match "/pads/share" => "pads#share"
  match "/pads/:id" => "pads#show"
end
