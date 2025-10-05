# Usage

```bash
.\vendor\builder.bat run debug
```

# Developing

Update submodules to fetch `ols`, then install it
```bash
git submodule update --init --remote --recursive
cd ols
.\build.bat # Or .sh for linux
```

Add Coc config:
```json
"languageserver": {
    "odin": {
        "command": "ols\\ols.exe",
            "filetypes": ["odin"],
            "rootPatterns": ["ols.json"]
    }
}
```
