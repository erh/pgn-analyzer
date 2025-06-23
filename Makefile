

module: dist/index.html
	tar czf module.tar.gz meta.json dist

dist/index.html: *.json src/*.css src/*.ts src/*.svelte src/lib/*.svelte node_modules
	NODE_ENV=development npm run build

bin:
	-mkdir bin

node_modules: package.json
	npm install

setup-linux:
	which npm > /dev/null 2>&1 || apt -y install nodejs
