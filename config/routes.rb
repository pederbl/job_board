Base::Application.routes.draw do
  resources :agreements

  resources :job_openings, path: 'jobb', constraints: { id: /.*/ } do 
    collection do
      get "more"
    end
  end

  root to: 'home#index'
  

end
