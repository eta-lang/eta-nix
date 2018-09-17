# Eta overlay for Nix

## Installation

```bash
git clone https://github.com/eta-lang/eta-nix.git
mkdir -p ~/.config/nixpkgs/overlays
ln -s $PWD/eta-nix/overlay.nix ~/.config/nixpkgs/overlays/eta-overlay.nix
```

## Usage

```bash
echo 'import Control.Lens' > Main.hs
echo 'main = itraverse_ (curry print) [1, 2, 3]' >> Main.hs
nix-shell -p 'etaPackages.etaWithPackages (p: [ p.lens ])' --run 'eta Main.hs'
```
