
build:
	swift build -c release && cp -f .build/release/Wallace /usr/local/bin/wallace
