# GitHub Setup Instructions

## Push to GitHub

1. **Create a new repository on GitHub**
   - Go to https://github.com/new
   - Repository name: `GHyprland`
   - Description: "Theme-agnostic Hyprland configuration with advanced Waybar modules"
   - Make it **Public** (so you can easily clone it on new machines) or **Private**
   - **Do NOT** initialize with README, .gitignore, or license (we already have these)

2. **Connect your local repository to GitHub**

   ```bash
   cd ~/GHyprland
   git remote add origin https://github.com/YOUR_USERNAME/GHyprland.git
   git branch -M main
   git push -u origin main
   ```

   Replace `YOUR_USERNAME` with your GitHub username.

3. **Update the README**

   After pushing, update the clone URL in README.md:
   ```bash
   cd ~/GHyprland
   # Edit README.md and replace YOUR_USERNAME with your actual username
   nano README.md
   git add README.md
   git commit -m "Update README with actual GitHub URL"
   git push
   ```

## Setting Up a New Computer

On your new Arch Linux machine:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/GHyprland.git ~/GHyprland

# Run the installation script
cd ~/GHyprland
./install.sh

# Log out and log back in
```

That's it! Your new system will be configured exactly like your current setup.

## Keeping Your Dotfiles Updated

### After making changes to your config files:

```bash
cd ~/GHyprland

# Copy updated configs (if not using symlinks)
cp ~/.config/hypr/*.conf ~/GHyprland/hypr/
cp ~/.config/waybar/config.jsonc ~/GHyprland/waybar/
cp ~/.config/waybar/style.css ~/GHyprland/waybar/
cp ~/.config/waybar/scripts/* ~/GHyprland/waybar/scripts/

# Or if using symlinks (recommended), changes are already in the repo

# Commit and push
git add .
git commit -m "Update configuration: describe your changes here"
git push
```

### Pull updates on another machine:

```bash
cd ~/GHyprland
git pull
./install.sh --skip-packages  # Refresh symlinks only
```

## Using SSH for Git (Recommended)

For easier pushing without entering password every time:

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Add SSH key to GitHub**:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   Copy the output and add it to GitHub at: https://github.com/settings/keys

3. **Change remote to SSH**:
   ```bash
   cd ~/GHyprland
   git remote set-url origin git@github.com:YOUR_USERNAME/GHyprland.git
   ```

Now you can push without entering credentials!

## Tips

- **Private vs Public**: If your configs contain any sensitive information (API keys, etc.), make the repository private
- **Branches**: Consider using branches for experimental changes before merging to main
- **Tags**: Tag stable configurations with git tags for easy rollback
- **Screenshots**: Add screenshots to your README to showcase your setup
