```bash
git clone -b etaPackages git@github.com:eta-lang/eta-nix.git
mkdir -p ~/.config/nixpkgs/overlays
ln -s $PWD/eta-nix/overlay.nix ~/.config/nixpkgs/overlays/eta-overlay.nix
nix-shell -p 'etaPackages.etaWithPackages (p: [ p.lens ])' --run 'eta Main.hs'
```
