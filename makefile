edit:
	mise exec -- tuist edit
install:
	mise exec -- tuist install
generate:
	mise exec -- tuist generate
generate_no_open:
	mise exec -- tuist generate --no-open
build:
	mise exec -- tuist build
clean:
	mise exec -- tuist clean
test:
	mise exec -- tuist test taskchamp
graph:
	mise exec -- tuist graph
debug:
	mise exec -- tuist build -- -configuration Debug
lint:
	swiftlint taskchamp/Sources --quiet
	swiftlint taskchampWidget/Sources --quiet
	swiftlint taskchampShared/Sources --quiet
	swiftlint taskchampShareExtension/Sources --quiet
format:
	swiftformat taskchamp/Sources
	swiftformat taskchampWidget/Sources
	swiftformat taskchampShared/Sources
	swiftformat taskchampShareExtension/Sources
clone_taskchampion:
	./scripts/clone_taskchampion_swift.sh
build_taskchampion:
	./scripts/build_taskchampion_swift.sh
up:
	make build_taskchampion
	make install
	make generate
