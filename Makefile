all:
	mkdir -p ./target
	elm-make src/Main.elm --output=target/index.html
	cp -r src/static/* target/static/
	cd target && python3 -m http.server
