# Git Quick Start Guide

## Initial Commit

```bash
cd fosdem_flutter

# Initialize and commit
git init
git add .
git commit -m "Initial commit: FOSDEM Flutter app with clean architecture"

# Set up remote (replace with your repo URL)
git remote add origin https://github.com/yourusername/fosdem-flutter.git
git branch -M main
git push -u origin main
```

## What's Included

### ✅ Tracked Files (146 files)
- Source code (`lib/**/*.dart`)
- Test files (`test/`, `e2e/`)
- Configuration (`pubspec.yaml`, `playwright.config.ts`)
- Platform files (Android, iOS, web, etc.)
- Documentation (README.md, etc.)

### 🚫 Ignored Files
- `node_modules/` - NPM dependencies
- `build/` - Flutter build output
- `.dart_tool/` - Dart tooling
- `test-results/` - Test results
- `playwright-report/` - Test reports
- `*.g.dart` - Generated code
- `.env` - Environment variables
- `*.db`, `*.sqlite` - Databases
- `coverage/` - Coverage reports

## Useful Commands

```bash
# Check status
git status

# Check what's ignored
git status --ignored

# Verify a file is ignored
git check-ignore node_modules/

# View ignored patterns
cat .gitignore

# Add specific files
git add lib/

# Commit changes
git commit -m "Your message"

# Push to remote
git push
```

## Branch Strategy

```bash
# Create feature branch
git checkout -b feature/event-list

# Work on feature
git add .
git commit -m "Add event list feature"

# Push feature branch
git push -u origin feature/event-list

# Merge to main
git checkout main
git merge feature/event-list
git push
```

## Tips

1. **Never commit**:
   - Dependencies (reinstall with `flutter pub get` / `npm install`)
   - Build artifacts (rebuild with `flutter build`)
   - Environment variables (use .env.example instead)
   - IDE settings (let each dev configure their own)

2. **Always commit**:
   - Source code changes
   - Configuration updates
   - Documentation changes
   - Test file updates

3. **Before committing**:
   ```bash
   flutter analyze
   flutter test
   npm test
   ```

## .gitignore Reference

Located at: `fosdem_flutter/.gitignore`

Key patterns:
- `node_modules/` - NPM packages
- `build/` - Build output
- `*.g.dart` - Generated files
- `.env` - Secrets
- `test-results/` - Test output

Full documentation: See `GIT_SETUP.md`

---

**Status**: Git is properly configured! Ready to commit and collaborate! 🚀
