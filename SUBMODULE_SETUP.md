# Adding DeskPad as a Submodule

This document provides instructions for adding DeskPad as a git submodule to this project.

## Prerequisites

You need to know the URL of the DeskPad repository. Common possibilities:
- `https://github.com/username/DeskPad.git`
- A private repository URL provided by your organization

## Steps to Add DeskPad Submodule

### 1. Add the Submodule

Run the following command from the root of this repository:

```bash
git submodule add <DESKPAD_REPO_URL> submodules/DeskPad
```

For example:
```bash
git submodule add https://github.com/example/DeskPad.git submodules/DeskPad
```

### 2. Initialize and Update

After adding the submodule, initialize and update it:

```bash
git submodule init
git submodule update
```

### 3. Commit the Changes

Commit the submodule addition:

```bash
git add .gitmodules submodules/DeskPad
git commit -m "Add DeskPad as submodule"
```

### 4. Verify the Submodule

Check that the submodule was added correctly:

```bash
git submodule status
```

You should see output like:
```
 <commit-hash> submodules/DeskPad (v1.0.0)
```

## Working with the Submodule

### Clone Repository with Submodules

When cloning this repository, use:

```bash
git clone --recursive <this-repo-url>
```

Or after cloning:

```bash
git submodule init
git submodule update
```

### Update Submodule to Latest Version

```bash
cd submodules/DeskPad
git pull origin main
cd ../..
git add submodules/DeskPad
git commit -m "Update DeskPad submodule"
```

### Switch to a Specific Submodule Version

```bash
cd submodules/DeskPad
git checkout <tag-or-commit>
cd ../..
git add submodules/DeskPad
git commit -m "Pin DeskPad to version X.Y.Z"
```

## Integration with DisplayControl Hook

Once DeskPad is added as a submodule:

1. Follow the integration guide in `Sources/PaperWM/INTEGRATION.md`
2. Copy `DisplayControlHook.swift` into the DeskPad project
3. Modify DeskPad's code to initialize the hook
4. Build and run DeskPad with the integrated hook

## Troubleshooting

### Submodule appears empty
```bash
git submodule update --init --recursive
```

### Permission denied
Make sure you have access to the DeskPad repository and your SSH keys are configured correctly.

### Detached HEAD in submodule
This is normal. Submodules track specific commits, not branches.
