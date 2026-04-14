Here are some cool things you can do with your Debian + Sway setup:
🪟 Sway/Wayland Enhancements
1. SwayFX - Replace sway with swayfx for window blur, shadows, and rounded corners:
      sudo apt install swayfx
   
2. Cool Waybar modules - Add CPU temp, weather, custom scripts:
   - ThinkPad-specific: Show which battery is being used, fan speed
   - Add a pomodoro timer, Spotify now-playing
3. Screenshot workflow - Install grim + slurp + wl-clipboard:
      grim -g "$(slurp)" - | wl-copy  # area screenshot to clipboard
   
4. Touchpad gestures - Install fusuma for macOS-like gestures on the trackpad
💻 Terminal Power-Ups (you already have zellij!)
5. Modern replacements for classic tools:
      sudo apt install fzf bat eza zoxide btop fd-find ripgrep
      - fzf - fuzzy finder for everything
   - bat - syntax-highlighted cat
   - eza - modern ls with icons
   - zoxide - smarter cd (learns your habits)
   - btop - beautiful system monitor
   - ripgrep - blazing fast grep
6. Neovim/LazyVim - If you haven't tried it, it's a game changer
🎵 Media & Fun
7. Music visualization - cava in your waybar or as a floating window:
      sudo apt install cava mpd mpc
   
8. ASCII art - asciiquarium or cmatrix for fun terminals:
      sudo apt install cmatrix asciiquatin
   
9. Gaming - Install Steam (yes, it works on Wayland now!):
      sudo apt install steam
   
🔧 ThinkPad-Specific
10. Battery thresholds - Use tlp to set charge limits (great for battery health):
        sudo apt install tlp tlp-rdw
    sudo tlp setcharge 40 80 BAT0  # keep between 40-80%
    
11. TrackPoint scrolling - Enable middle-button + TrackPoint scrolling in Sway config
12. Fan control - thinkfan for custom fan curves
🐳 Self-Hosting / Services
13. Docker/Podman - Run your own services:
    - Nextcloud, Jellyfin, AdGuard Home, Pi-hole
    - Your own AI models (ollama + open-webui)
14. Flatpak apps - Better sandboxed apps:
        flatpak install flathub com.spotify.Client
    flatpak install flathub com.visualstudio.code
    
🔒 Privacy & Security
15. QEMU/KVM - Your CPU supports virtualization, run Windows/macOS/other distros:
        sudo apt install qemu-kvm virt-manager
    
16. WireGuard - Easy VPN server/client setup
⚡ Quick Terminal Workflow Ideas
17. Tmux/zellij session restore - Resume your work exactly where you left off
18. Directory jumper - Combine zoxide with fzf for instant navigation:
        z foo  # jump to most frecent dir matching 'foo'
    zi foo # interactive selection with fzf
    
Want me to help set up any of these? I can install and configure them for you!
