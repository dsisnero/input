# input

Crystal port of the
[charmbracelet/x/input](https://github.com/charmbracelet/x/tree/main/input) Go
package.

This library provides terminal input event handling, including keyboard, mouse,
and clipboard events with support for various terminal types and escape sequence
parsing.

**Source:**
[github.com/charmbracelet/x/input](https://github.com/charmbracelet/x/tree/main/input)
(commit `eeb2896ac7594d35cba4e742283e2fa20aa8b7fb`)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     input:
       github: dsisnero/input
   ```

2. Run `shards install`

## Usage

```crystal
require "input"

# TODO: Add usage examples from the Go package documentation
# The port aims to provide the same API as the Go package with Crystal idioms.
```

## Development

Standard development tasks are available via Makefile:

```bash
make install    # Install dependencies
make update     # Update dependencies
make format     # Check code formatting
make lint       # Run linter (ameba)
make test       # Run tests
make clean      # Clean temporary files
```

## Porting Status

This is an ongoing port from Go to Crystal. The source code is available in the
`vendor/` submodule.

## Recent Updates

- Added GitHub Actions CI for Linux and Windows specs.
- Ported Windows console input parity paths (`cancelreader`, `ReadEvents` console flow, key/mouse/focus/window event parsing).
- Completed Go `TestParseSequence` matrix parity in Crystal specs.
- Added Crystal equivalents for Go fuzz/benchmark-style parser safety coverage.

## Contributing

1. Fork it (<https://github.com/dsisnero/input/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

When contributing to this port, please follow the porting guidelines:

- Maintain exact logic from the Go source
- Use Crystal idioms for syntax and structure
- Port corresponding tests for each function
- Ensure all tests pass before submitting changes

## Contributors

- [Dominic Sisneros](https://github.com/dsisnero) - creator and maintainer
- Original Go package authors: [Charmbracelet](https://github.com/charmbracelet)
