
site.html: params.json site.erb.html
	erb -r json site.erb.html > site.html

params.json: options.rb
	ruby options.rb > params.json
