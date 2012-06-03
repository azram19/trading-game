# Order is EXTREMELY important here
ENGINE = GameObject.js ObjectState.js Field.js Signal.js Types.js Properties.js Uid.js SignalFactory.js HQBehaviour.js ChannelBehaviour.js PlatformBehaviour.js ResourceBehaviour.js ObjectFactory.js Map.js GameManager.js 

all: dir | js css
	cp dev/build/*.js dev/webroot/js

clean:
	rm -rf dev/build

dir:
	mkdir -p dev/build/templates
	mkdir -p dev/build/engine

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
	find dev/common -name *.coffee -exec node_modules/.bin/coffee -co dev/build/engine {} +
	cd dev/build/engine; \
	cat $(ENGINE) > ../../webroot/js/engine.js

css:
	node_modules/.bin/lessc -x dev/webroot/css/style.less > dev/webroot/css/style.css

loc:
	find dev -name *.coffee -exec cat {} + | sed '/^\s*#/d;/^\s*$$/d' | wc -l
