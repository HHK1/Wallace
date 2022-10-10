
build:
	swift build -c release && cp -f .build/release/Wallace /usr/local/bin/wallace && wallace --generate-completion-script > ~/.oh-my-zsh/completions/_wallace
