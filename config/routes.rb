Base::Application.routes.draw do
  resources :agreements

  resources :job_openings, path: 'j', constraints: { id: /.*/ } do 
    collection do
      get "more"
      get "job_categories_picker_node_children" 
      get "locations_picker_node_children" 
    end
  end

  resources :job_openings, path: 'jobb', constraints: { id: /.*/ } do 
    collection do
      get "more"
    end
  end

  root to: 'home#index'
end
