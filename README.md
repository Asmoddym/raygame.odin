# Initialize repo

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
And optionally custom config from ols
