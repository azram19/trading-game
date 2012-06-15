# Order is EXTREMELY important here
ENGINE = Namespace.js HeightMap.js  GameObject.js ObjectState.js Field.js Signal.js Types.js Player.js Properties.js SignalFactory.js HQBehaviour.js ChannelBehaviour.js PlatformBehaviour.js ResourceBehaviour.js ObjectFactory.js Map.js GameManager.js
RENDERER = Human.js Board.js MenuDisplayHelper.js MapHelper.js RadialMenu.js UI.js Terrain.js

all: dir | js css
	cp dev/build/*.js dev/webroot/js

clean:
	rm -rf dev/build
	rm -f dev/webroot/js/*.js

dir:
	mkdir -p dev/build/templates
	mkdir -p dev/build/engine
	mkdir -p dev/build/renderer

js-renderer:
	find dev/client/renderer -name *.coffee -exec node_modules/.bin/coffee -co dev/build/renderer {} +
	cd dev/build/renderer; \
	cat $(RENDERER) > ../../webroot/js/renderer.js

js-templates:
	find dev/client/templates -name *.handlebars -print0 | xargs -I {} -0 sh -c 'f=`basename {}`; node_modules/.bin/handlebars {} -f dev/build/templates/`basename {}`.js'
	rm -f dev/webroot/js/templates.js
	cat dev/build/templates/* > dev/webroot/js/templates.js

js-views:
	find dev/client/views -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/views.js {} +
	cp dev/build/views.js dev/webroot/js

js-models:
	find dev/client/models -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/models.js {} +
	cp dev/build/models.js dev/webroot/js

js-collections:
	find dev/client/collections -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/collections.js {} +
	cp dev/build/collections.js dev/webroot/js

js-general:
	find dev/client -maxdepth 1 -name *.coffee -exec node_modules/.bin/coffee -cj dev/build/signals.js {} +
	cp dev/build/signals.js dev/webroot/js

js-engine:
	find dev/common -name *.coffee -exec node_modules/.bin/coffee -co dev/build/engine {} +
	cd dev/build/engine; \
	cat $(ENGINE) > ../../webroot/js/engine.js

js: js-templates js-views js-models js-collections js-renderer js-engine js-general

css:
	node_modules/.bin/lessc -x dev/webroot/css/style.less > dev/webroot/css/style.css

loc:
	find dev -name *.coffee -exec cat {} + | sed '/^\s*#/d;/^\s*$$/d' | wc -l
