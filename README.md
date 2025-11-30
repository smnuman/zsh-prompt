# 🪶 Numan Prompt

A minimal, lightning-fast, and elegant Zsh prompt designed for modern terminal workflows.  
Built as a **stand-alone module**, yet seamlessly integrable into the broader **NOMAD environment**.

---

## 🚀 Features

- Blazing-fast async rendering (built for Zsh)
- Smart Git status indicators
- Subtle colour cues for mode and context
- Compatible with Nerd Fonts and Powerline symbols
- Fully customisable without breaking your setup

---

## 🧩 Requirements

| Component | Minimum Version | Notes |
|------------|-----------------|-------|
| **Zsh** | 5.8+ | Required shell |
| **Nerd Font** | Any | For icons/symbols |
| **git** | 2.30+ | For Git branch/status display |
| **Optional** | `bat`, `lsd`, `eza`, or `starship` | Enhances information display |

---

## ⚙️ Installation

### 1️⃣ Clone the prompt as a stand-alone module
```bash
cd ~/.config/zsh
git clone --depth=1 git@github.com:smnuman/prompt.git
```

### 2️⃣ Source it in your `.zshrc` (or modular loader)
```bash
# If using a modular config (recommended)
zsh_add_file "$ZDOTDIR/prompt/prompt.zsh"

# Or simply:
source ~/.config/zsh/prompt/prompt.zsh
```

### 3️⃣ (Optional) Customise
All visual and logical elements are defined in `prompt.zsh`.  
You can safely modify colours, symbols, or line structure to match your workflow.

---

## 🔄 Updating
If used as a **Git submodule** under `~/.config/zsh` or `~/.config`, simply run:
```bash
gsubmod "Update prompt module"
```

If used stand-alone:
```bash
git pull origin main
```

---

## 🧠 Usage

Once installed and sourced, the prompt automatically:
- Displays your working directory and Git branch.
- Highlights the exit code when a command fails.
- Adapts dynamically to terminal width.
- Keeps itself lightweight (<5 ms render time).

No additional commands required — it just works. 🪄

---

## 🌍 Contributing & Adaptation

This project is part of the evolving **NOMAD system**, a modular, portable workflow for creative developers.  
You’re warmly invited to **adapt, improve, or fork** it for your own use.

- Found a better layout? Submit a PR.  
- Want extra symbols or right-side info? Extend it!  
- Prefer minimal colours? Fork and tweak — it’s yours.

💡 Every contribution that improves clarity, efficiency, or aesthetic consistency is welcome.

---

## 📜 Licence

Released under the **MIT Licence** — free to use, modify, and distribute.  
Credit is appreciated but not required.

---

**Author:** [Numan Syed](https://github.com/smnuman)  
**Part of:** [NOMAD Config System](https://github.com/smnuman/dotconfig)
