appraise 'activerecord-4.1' do
  gem 'activerecord', '~> 4.1.0'
  gem 'foreigner', :git => 'https://github.com/matthuhiggins/foreigner.git'
  platforms :ruby, :rbx do
    gem 'mysql2', '~> 0.3.20'
  end
end

appraise 'activerecord-4.2' do
  gem 'activerecord', '~> 4.2.0'
  platforms :ruby, :rbx do
    gem 'mysql2', '~> 0.3.20'
  end
end

appraise 'activerecord-edge' do
  gem 'activerecord', github: 'rails/rails'
  gem 'arel', github: 'rails/arel'
end
