# Architecture Documentation

## System Overview

The Claude-Integrated Lisp Desktop is a unified environment that combines:

1. **StumpWM** - The tiling window manager (Lisp host)
2. **Swank/SLY** - REPL server for interactive development
3. **Claude API** - Natural language AI interface
4. **Emacs** - Text editor with bidirectional integration

## Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User Layer                            │
│  • Keyboard Input (Super+Space, etc.)                        │
│  • Emacs Commands (M-x claude-ask)                           │
│  • Natural Language Prompts                                  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    Command Layer                             │
│  ┌────────────────┐         ┌──────────────────┐            │
│  │ StumpWM        │         │ Emacs            │            │
│  │ Commands       │◄───────►│ claude-mode.el   │            │
│  │ (claude-ask)   │         │ stumpctl.el      │            │
│  └────────┬───────┘         └────────┬─────────┘            │
└───────────┼──────────────────────────┼──────────────────────┘
            │                          │
            ▼                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 Integration Layer                            │
│  ┌──────────────────────────────────────────────────┐       │
│  │           Swank/SLY REPL Server                  │       │
│  │           Port 4005 (localhost)                  │       │
│  │                                                   │       │
│  │  • Bidirectional code execution                  │       │
│  │  • Shared Lisp environment                       │       │
│  │  • Hot-reload capabilities                       │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Service Layer                              │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────┐       │
│  │ Context      │  │ Claude API  │  │ HTTP Client  │       │
│  │ Gathering    │─►│ Integration │─►│ (curl-based) │       │
│  └──────────────┘  └─────────────┘  └──────────────┘       │
│                           │                                  │
│                           ▼                                  │
│                  ┌─────────────────┐                         │
│                  │ Claude API      │                         │
│                  │ (External)      │                         │
│                  └─────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Execution Layer                            │
│  • Window Management (StumpWM API)                           │
│  • Application Launching (shell commands)                    │
│  • Lisp Code Evaluation                                      │
│  • X11 Interaction                                           │
└─────────────────────────────────────────────────────────────┘
```

## Module Breakdown

### Core Modules

#### 1. init.lisp
- **Purpose**: Entry point for StumpWM configuration
- **Responsibilities**:
  - Load all configuration and modules in correct order
  - Display startup messages
  - Initialize Swank server (optional)
- **Dependencies**: None (loads all others)

#### 2. config/core.lisp
- **Purpose**: Core StumpWM settings
- **Configuration**:
  - Window borders, focus policy
  - Workspace definitions
  - Claude API settings
  - Debug flags
- **Dependencies**: None

#### 3. config/theme.lisp
- **Purpose**: Visual appearance
- **Configuration**:
  - Colors (Base16-inspired palette)
  - Fonts
  - Mode line format
- **Dependencies**: None

#### 4. config/commands.lisp
- **Purpose**: Custom StumpWM commands
- **Provides**:
  - Window management helpers
  - Application launchers
  - System commands
- **Dependencies**: utils.lisp

#### 5. config/keybindings.lisp
- **Purpose**: All keybindings
- **Bindings**:
  - Super key bindings (modern, intuitive)
  - Traditional C-t prefix bindings (compatibility)
  - Media keys
- **Dependencies**: All command modules

### Library Modules

#### 6. lib/utils.lisp
- **Purpose**: General utility functions
- **Provides**:
  - String manipulation
  - File I/O
  - JSON encoding/decoding
  - Logging
  - Error handling
- **Dependencies**: None

#### 7. lib/http-client.lisp
- **Purpose**: HTTP client for Claude API
- **Implementation**: Uses `curl` via shell commands
- **Provides**:
  - POST/GET requests
  - JSON body handling
  - Response parsing
- **Dependencies**: utils.lisp

### Integration Modules

#### 8. modules/claude-swank.lisp
- **Purpose**: Swank/SLY REPL server
- **Provides**:
  - Start/stop Swank server
  - Connection management
  - Quicklisp integration
  - Code evaluation
- **Port**: 4005 (default)
- **Dependencies**: Swank (external, via Quicklisp)

#### 9. modules/context-gathering.lisp
- **Purpose**: Desktop state introspection
- **Gathers**:
  - Current window information
  - Workspace/group state
  - Frame layout
  - System information
- **Format**: Property lists → human-readable strings
- **Dependencies**: utils.lisp

#### 10. modules/claude-integration.lisp
- **Purpose**: Core Claude API integration
- **Provides**:
  - API request handling
  - System prompt management
  - Code extraction from responses
  - Conversation history
- **Dependencies**: http-client.lisp, context-gathering.lisp

#### 11. modules/claude-commands.lisp
- **Purpose**: User-facing Claude commands
- **Commands**:
  - `:claude-ask` - Main query interface
  - `:claude-do` - Execute commands
  - `:claude-eval-region` - Run code
  - Many specialized commands
- **Dependencies**: claude-integration.lisp

### Emacs Integration

#### 12. emacs/stumpctl.el
- **Purpose**: Control StumpWM from Emacs
- **Provides**:
  - SLY connection management
  - Command execution
  - Code evaluation in StumpWM
  - Window management functions
- **Dependencies**: SLY (Emacs package)

#### 13. emacs/claude-mode.el
- **Purpose**: Claude integration in Emacs
- **Provides**:
  - Claude query interface
  - Code explanation/generation
  - StumpWM command generation
  - Conversation buffer
- **Dependencies**: request.el, stumpctl.el

## Data Flow

### Typical Command Flow

1. **User Input**
   ```
   User presses Super+Space
   → StumpWM keybinding triggers :claude-ask command
   ```

2. **Context Gathering**
   ```
   claude-ask calls gather-full-context
   → Collects window titles, workspace info, etc.
   → Formats as human-readable text
   ```

3. **Prompt Construction**
   ```
   Context + User prompt → Full prompt
   System prompt defines Claude's role
   ```

4. **API Request**
   ```
   claude-api-request constructs JSON
   → http-post-json uses curl to call API
   → Response parsed and returned
   ```

5. **Response Processing**
   ```
   Extract text from JSON response
   Check for Lisp code blocks (```lisp ... ```)
   → If code found and execute-code=t, evaluate it
   → Otherwise, display message to user
   ```

6. **Execution**
   ```
   (eval (read-from-string code))
   → Lisp code runs in StumpWM process
   → Changes window state, launches apps, etc.
   ```

### Emacs → StumpWM Flow

1. **User in Emacs**
   ```
   M-x claude-stumpwm-command "tile browser and terminal"
   ```

2. **Claude Generates Code**
   ```
   Returns: (progn (stumpwm:gselect "main") (stumpwm:hsplit) ...)
   ```

3. **Execute via SLY**
   ```
   stumpctl-eval sends code through Swank connection
   → Evaluated in StumpWM's Lisp process
   → Desktop changes immediately
   ```

## State Management

### Persistent State
- **Conversation History**: Last 10 exchanges
- **Configuration**: Loaded from Lisp files on startup
- **Window State**: Managed by StumpWM (X11)

### Transient State
- **Current Context**: Gathered fresh for each query
- **API Responses**: Cached only for current session
- **Connection State**: Swank server running/stopped

## Extension Points

### Adding New Commands

1. Define command in `config/commands.lisp` or `modules/claude-commands.lisp`
2. Add keybinding in `config/keybindings.lisp`
3. Optionally expose via Emacs in `stumpctl.el`

### Adding New Context

1. Add gathering function in `modules/context-gathering.lisp`
2. Call from `gather-full-context`
3. Format in `format-context-for-claude`

### Customizing Claude Behavior

1. Modify `*claude-system-prompt*` in `modules/claude-integration.lisp`
2. Adjust context inclusion flags in `config/core.lisp`
3. Add specialized query functions

## Security Considerations

### API Key Storage
- Read from environment variable
- Never committed to git
- Can be set per-session

### Code Execution
- Claude-generated code runs with full StumpWM privileges
- **Risk**: Malicious code could control entire desktop
- **Mitigation**:
  - Review code before running with `:claude-do`
  - Use `:claude-ask` (no auto-exec) by default
  - Trust in Claude's safety training

### Network Security
- All API calls over HTTPS
- Swank server bound to localhost only
- No external services besides Claude API

## Performance

### Latency
- Context gathering: <10ms
- API request: 500-3000ms (network + Claude)
- Code execution: <10ms
- Total: ~1-3 seconds per query

### Resource Usage
- StumpWM process: ~50MB RAM
- Swank overhead: ~10MB RAM
- No significant CPU usage when idle

## Future Enhancements

### Planned Features
1. **Persistent Claude context**: Remember longer conversations
2. **Voice input**: Integrate with speech-to-text
3. **Multi-modal**: Screenshot analysis via Claude
4. **Learning mode**: Teach Claude custom commands
5. **Desktop automation**: Recorded workflows

### Potential Integrations
- **Org-mode**: Task management via Claude
- **EXWM**: Emacs as window manager
- **Rofi/Dmenu**: Alternative prompt interfaces
- **Wayland**: Port to Wayland compositors

## Debugging

### Log Files
- Location: `~/.stumpwm.d/stumpwm.log`
- Enable: Set `*claude-debug* t` in `config/core.lisp`

### REPL Access
- Start Swank: `Super+Ctrl+S` or `:swank-start`
- Connect from Emacs: `M-x sly-connect`
- Evaluate: `(in-package :stumpwm)`

### Testing Components
- HTTP client: `:test-http-client`
- Claude API: `:test-claude-api`
- Context: `:claude-context`
- Connection: `:claude-test`

## License

GPLv3 - See LICENSE file
