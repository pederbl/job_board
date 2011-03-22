Base::Application.routes.draw do
  resources :job_openings, path: 'jobb', constraints: { id: /.*/ }
  
  root to: 'home#index'
  

end
