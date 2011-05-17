Base::Application.routes.draw do
  resources :geonames_locations do 
    collection do 
      get "search"
    end
  end

  resources :agreements

  resources :job_openings, path: 'j', constraints: { id: /.*/ } do 
    collection do
      get "more"
      get "location_picker_node_children" 
    end
  end

  resources :job_openings, path: 'jobb', constraints: { id: /.*/ } do 
    collection do
      get "more"
    end
  end

  root to: 'home#index'
  

end
