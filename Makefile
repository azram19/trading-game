all: dir | js
	cp dev/build/*.js dev/webroot/js

dir:
	mkdir -p dev/build/templates

js-renderer:
	find dev/client/renderer -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/renderer.js {} +

js-templates:
	find dev/client/templates -name *.handlebars -print0 | xargs -I {} -0 sh -c 'f=`basename {}`; node_modules/.bin/handlebars {} -f dev/build/templates/`basename {}`.js'
	rm -f dev/webroot/js/templates.js
	cat dev/build/templates/* > dev/webroot/js/templates.js

js-views:
	find dev/client/views -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/views.js {} +

js-models:
	find dev/client/models -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/models.js {} +

js-collections:
	find dev/client/collections -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/collections.js {} +

js: js-templates js-views js-models js-collections js-renderer js-engine
	find dev/client -maxdepth 1 -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/signals.js {} +

js-engine:
	find dev/common -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/engine.js {} +

loc:
	find dev -name *.coffee -exec cat {} + | sed '/^\s*#/d;/^\s*$$/d' | wc -l
