# Flatpak Integration Design for StumpWM

## Overview
Seamless Flatpak application management from StumpWM with interactive search/install interface and Emacs log integration.

## Architecture

### 1. Core Module: `modules/flatpak.lisp`
Primary Flatpak integration module providing:
- Search functionality with caching
- Installation/removal with background processing
- Update management
- Application metadata handling

### 2. Log Integration: File-based with Emacs viewing
Following the `stumpwm-eval.lisp` pattern:
- All Flatpak operations log to: `/tmp/flatpak-stumpwm.log`
- Real-time streaming during install/operations
- Emacs can tail the log file with auto-refresh
- Structured log format for easy parsing

### 3. Interactive UI Components

#### A. Search Interface
```
Command: flatpak-search "obs"
Display: StumpWM menu with:
  - Application name
  - App ID (com.obsproject.Studio)
  - Version
  - Description (truncated)
  - Install status (installed/available)

Navigation:
  - Up/Down arrows to select
  - Enter to install
  - 'i' for more info
  - 'q' to quit
```

#### B. Installation Progress
```
During install:
  - Background process with flatpak install
  - Progress logged to /tmp/flatpak-stumpwm.log
  - StumpWM messages for status updates
  - Emacs can tail -f the log for real-time view
```

#### C. Installed Apps Manager
```
Command: flatpak-list
Display: Menu of installed apps with:
  - Name, Version, Size
  - Actions: Launch, Uninstall, Update
```

## Key Features

### 1. Search & Discovery
- **Command**: `flatpak-search QUERY`
- **Implementation**:
  - Run: `flatpak search --columns=name,application,version,description QUERY`
  - Parse output into structured list
  - Cache results for 5 minutes
  - Display in StumpWM selection menu
  - Select app → trigger install

### 2. Installation
- **Command**: `flatpak-install APP-ID`
- **Implementation**:
  ```lisp
  (defun flatpak-install-async (app-id)
    "Install Flatpak app in background with logging"
    (let ((log-file "/tmp/flatpak-stumpwm.log"))
      ;; Log start
      (log-flatpak-event :install :started app-id)

      ;; Run in thread (like Slynk server pattern)
      (sb-thread:make-thread
       (lambda ()
         (run-shell-command
           (format nil "flatpak install -y flathub ~A >> ~A 2>&1"
                   app-id log-file))
         (log-flatpak-event :install :completed app-id)
         (message (format nil "✓ Installed: ~A" app-id)))
       :name (format nil "flatpak-install-~A" app-id))))
  ```

### 3. Listing Installed Apps
- **Command**: `flatpak-list`
- Parse: `flatpak list --app --columns=name,application,version,size`
- Display in menu with launch/uninstall options

### 4. Updates
- **Command**: `flatpak-update-all`
- Run: `flatpak update -y` in background
- Show progress in logs

### 5. Quick Launch
- **Command**: `flatpak-run APP-ID`
- Add to keybindings for common apps
- Example: `(define-key *top-map* (kbd "M-O") "flatpak-run com.obsproject.Studio")`

## Data Structures

```lisp
(defstruct flatpak-app
  name           ; Human-readable name
  app-id         ; Full ID (com.obsproject.Studio)
  version        ; Version string
  description    ; Description
  installed-p    ; Boolean
  size           ; Disk size (if installed)
  branch)        ; stable/beta/etc

(defparameter *flatpak-cache* (make-hash-table :test 'equal)
  "Cache for search results and installed apps")

(defparameter *flatpak-log-file* "/tmp/flatpak-stumpwm.log"
  "Log file for all Flatpak operations")
```

## Commands Summary

### Primary Commands
1. `flatpak-search QUERY` - Interactive search & install
2. `flatpak-install APP-ID` - Install specific app
3. `flatpak-list` - Show installed apps (interactive)
4. `flatpak-remove APP-ID` - Uninstall app
5. `flatpak-update-all` - Update all apps
6. `flatpak-run APP-ID` - Launch Flatpak app
7. `flatpak-show-log` - Open log in Emacs or show last 50 lines

### Utility Commands
8. `flatpak-info APP-ID` - Show detailed app info
9. `flatpak-clear-cache` - Clear search cache
10. `flatpak-status` - Show Flatpak system status

## Emacs Integration

### Option 1: Dedicated Log Buffer (Simple)
```elisp
;; Add to .emacs or stumpctl.el
(defun stumpwm-flatpak-log ()
  "Open StumpWM Flatpak log in auto-refresh buffer"
  (interactive)
  (let ((buf (get-buffer-create "*StumpWM Flatpak*")))
    (with-current-buffer buf
      (auto-revert-tail-mode 1)
      (setq-local auto-revert-interval 1)
      (view-mode 1))
    (find-file-literally "/tmp/flatpak-stumpwm.log")
    (switch-to-buffer buf)))
```

### Option 2: Interactive Manager (Advanced)
```elisp
;; Full Emacs UI for Flatpak management
(defun stumpwm-flatpak-manager ()
  "Interactive Flatpak manager in Emacs"
  (interactive)
  ;; Read from StumpWM via stumpctl
  ;; Display in tabulated-list-mode
  ;; Actions: install, remove, update
)
```

## File Structure

```
~/.stumpwm.d/
├── modules/
│   └── flatpak.lisp          # Main Flatpak module
├── desktop/
│   └── keys.lisp             # Add flatpak keybindings
└── init.lisp                 # Load flatpak module

/tmp/
└── flatpak-stumpwm.log       # Operation logs

~/.emacs.d/
└── stumpctl.el (or init.el)  # Emacs integration
```

## Log Format

Structured, easily parseable:
```
[2025-01-15 14:30:15] SEARCH "obs" - 5 results found
[2025-01-15 14:30:45] INSTALL STARTED: com.obsproject.Studio
[2025-01-15 14:30:46] OUTPUT: Installing: com.obsproject.Studio/x86_64/stable
[2025-01-15 14:31:20] OUTPUT: Download complete
[2025-01-15 14:31:22] INSTALL COMPLETED: com.obsproject.Studio (35s)
[2025-01-15 14:32:00] LAUNCH: com.obsproject.Studio
```

## Implementation Phases

### Phase 1: Core Module (Essential)
- [x] Design architecture
- [ ] Parse flatpak search output
- [ ] Parse flatpak list output
- [ ] Implement flatpak-install-async
- [ ] Logging infrastructure
- [ ] Basic commands (search, install, list)

### Phase 2: Interactive UI
- [ ] Search menu with selection
- [ ] Installed apps menu
- [ ] Progress indicators
- [ ] Error handling & messages

### Phase 3: Emacs Integration
- [ ] Log viewing function
- [ ] Auto-refresh setup
- [ ] Optional: interactive manager

### Phase 4: Polish
- [ ] Caching system
- [ ] Update management
- [ ] Quick launch keybindings
- [ ] Integration with desktop/keys.lisp

## Usage Example: Installing OBS

### Method 1: Interactive Search
```
User: M-DEL : flatpak-search obs
StumpWM: Shows menu with OBS Studio
User: Select with arrows, press Enter
StumpWM: "Installing OBS Studio... (see log: M-DEL : flatpak-show-log)"
[Background install proceeds]
StumpWM: "✓ OBS Studio installed"
```

### Method 2: Direct Install
```
User: M-DEL : flatpak-install com.obsproject.Studio
StumpWM: "Installing... check /tmp/flatpak-stumpwm.log"
[In Emacs: M-x stumpwm-flatpak-log to watch live]
```

### Method 3: Launch After Install
```
User: M-DEL : flatpak-run com.obsproject.Studio
[Or keybinding: M-O for OBS]
```

## Benefits

1. **Seamless**: No terminal needed, all in StumpWM
2. **Transparent**: All operations logged, visible in Emacs
3. **Non-blocking**: Background installs don't freeze WM
4. **Discoverable**: Search makes finding apps easy
5. **Integrated**: Fits existing StumpWM/Emacs workflow
6. **Maintainable**: Follows existing module patterns

## Questions for User

1. **Search Results**: How many results to show? (default: top 10?)
2. **Auto-launch**: Launch app after install? (prompt or automatic?)
3. **Keybindings**: Preferred keys for flatpak-search and flatpak-list?
4. **Emacs Integration**: Simple log viewer or full manager?
5. **Notifications**: Use StumpWM messages, desktop notifications, or both?
6. **Remote Sources**: Only Flathub, or add other remotes?

## Next Steps

1. Review this design
2. Answer questions above
3. Implement Phase 1 (core module)
4. Test with OBS installation
5. Add Emacs log viewer
6. Iterate based on usage
