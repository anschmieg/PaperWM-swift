# Contributing to PaperWM-swift

Thank you for your interest in contributing to PaperWM-swift! This guide will help you get started.

## Development Setup

1. **Fork and clone the repository:**
   ```bash
   git clone --recursive https://github.com/YOUR_USERNAME/PaperWM-swift.git
   cd PaperWM-swift
   ```

2. **Build the project:**
   ```bash
   make build
   ```

3. **Run tests:**
   ```bash
   make test
   ./Tests/integration-test.sh
   ./Tests/e2e-smoke-test.sh
   ```

## Project Structure

- **Tools/deskpadctl** - Swift CLI tool for controlling DeskPad displays
- **Integration/DeskPad** - DisplayControl component and integration files
- **Scripts/** - Helper scripts for canvas management
- **Tests/** - Test suites (integration and E2E)
- **submodules/DeskPad** - DeskPad as a git submodule

## Making Changes

### Before You Start

1. Create a new branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make sure all tests pass before making changes:
   ```bash
   make test
   ```

### While Developing

1. **Follow Swift best practices:**
   - Use meaningful variable names
   - Add comments for complex logic
   - Follow existing code style

2. **Test your changes:**
   - Add unit tests for new functionality
   - Update integration tests if needed
   - Run all tests before committing

3. **Keep changes minimal:**
   - Focus on one feature or fix per PR
   - Don't refactor unrelated code
   - Keep the DeskPad submodule unmodified

### Adding New Features

#### Adding a new deskpadctl command:

1. Add the command structure in `Tools/deskpadctl/Sources/deskpadctl/deskpadctl.swift`
2. Implement the command logic
3. Add tests in `Tools/deskpadctl/Tests/deskpadctlTests/`
4. Update README with new command documentation

Example:
```swift
extension DeskPadCTL {
    struct YourCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Description of your command"
        )
        
        func run() throws {
            // Implementation
        }
    }
}
```

#### Adding a new script:

1. Create the script in `Scripts/`
2. Make it executable: `chmod +x Scripts/your-script.sh`
3. Add help text with `--help` flag
4. Test the script manually
5. Add test to `Tests/integration-test.sh`

#### Extending DisplayControl:

1. Edit `Integration/DeskPad/DisplayControl.swift`
2. Document changes in `Integration/DeskPad/DISPLAYCONTROL_INTEGRATION.md`
3. Test with actual DeskPad integration if possible
4. Update integration instructions in `Integration/DeskPad/README.md`

## Testing

### Unit Tests
```bash
cd Tools/deskpadctl
swift test
```

### Integration Tests
```bash
./Tests/integration-test.sh
```

### E2E Smoke Tests
```bash
./Tests/e2e-smoke-test.sh
```

### Manual Testing on macOS

For testing actual DeskPad integration:

1. Copy DisplayControl to DeskPad:
   ```bash
   cp Integration/DeskPad/DisplayControl.swift submodules/DeskPad/DeskPad/
   ```

2. Build DeskPad in Xcode

3. Run DeskPad

4. Test deskpadctl commands:
   ```bash
   deskpadctl create --width 1920 --height 1080
   deskpadctl list
   ```

## Code Review Checklist

Before submitting a PR, ensure:

- [ ] All tests pass
- [ ] Code follows existing style conventions
- [ ] New features have tests
- [ ] Documentation is updated
- [ ] Commit messages are clear and descriptive
- [ ] No unnecessary changes to unrelated code
- [ ] DeskPad submodule remains unmodified

## Commit Messages

Use clear, descriptive commit messages:

```
Add feature: Brief description

- Detailed point 1
- Detailed point 2
```

## Pull Request Process

1. Update the README.md with details of changes if needed
2. Update tests to cover new functionality
3. Ensure all tests pass
4. Submit PR with clear description of changes
5. Wait for code review and address feedback

## Questions?

If you have questions:

1. Check existing documentation
2. Review the code and tests
3. Open an issue for discussion

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
