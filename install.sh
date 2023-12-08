set -ex

systemctl start wpa_supplicant
sleep 2
interface=
network_id=$(wpa_cli -i $interface add_network)
ssid=
psk=
wpa_cli -i $interface set_network $network_id ssid '"'"$ssid"'"'
if [ -z "${psk}" ]; then
  wpa_cli -i $interface set_network $network_id psk '"'"$psk"'"'
else
  wpa_cli -i $interface set_network $network_id key_mgmt NONE
fi
wpa_cli -i $interface enable_network $network_id sleep 5
wpa_cli -i $interface status sleep 10

ping -c 1 1.1.1.1
curl https://httpbin.org/ip

mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
echo "nix run github:nix-community/disko -- --mode disko --flake \$PWD#laptop"
echo "nixos-install --flake \$PWD#laptop"
exec nix shell nixpkgs#emacs nixpkgs#git
