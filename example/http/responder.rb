module HTTP
  class Responder < RDKit::HTTPResponder
    get '/hello' do
      [200, {}, ['OK']]
    end
  end
end
