all:
	mkdir -p ./target
	elm-make src/Main.elm --output=target/index.html
	cd target && python3 -m http.server
