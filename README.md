# ⚠️ Ordre de déploiement recommandé

Il faut procéder par étapes :

1. **Commente d'abord la création du Customer Gateway côté Scaleway** et le fichier `aws.tf` pour récupérer l'IP publique de la VPN Gateway côté Scaleway.
2. **Décommente ensuite côté AWS** pour obtenir l'IP du tunnel concerné.
3. **Fournis enfin le bon PSK** pour finaliser la liaison (récupère le PSK Scaleway et renseigne-le côté AWS).


# Guide de mise en place VPN Site-to-Site AWS <-> Scaleway

Ce guide explique comment déployer un tunnel VPN site-à-site entre AWS et Scaleway avec Terraform, en suivant les bonnes pratiques du guide officiel.

## Prérequis
- Accès à un compte AWS et Scaleway
- Terraform installé
- Accès aux credentials AWS et Scaleway

## 1. Préparer les variables

- Renseigner les variables d'accès dans `scaleway.auto.tfvars` et les variables AWS dans vos fichiers d'environnement.
- Définir le CIDR du VPC AWS dans `aws_plage` (ex : `10.1.0.0/16`).

## 2. Déployer l'infrastructure Scaleway

```sh
cd /Users/youssoupphasow/Documents/pocs/printemps
terraform init
terraform apply
```
- Cela va créer le VPC, le réseau privé, la gateway publique, le cluster Kapsule, et la gateway VPN côté Scaleway.

## 3. Déployer l'infrastructure AWS

- Vérifier que la variable `scw_vpn_public_ip` correspond à l'IP publique de la gateway Scaleway.
- Lancer :
```sh
terraform init
terraform apply
```
- Cela va créer le VPC, les subnets, la customer gateway (pointant vers Scaleway), la VPN gateway et la connexion VPN côté AWS.

## 4. Récupérer les paramètres BGP et tunnels

- Après l'apply AWS, récupérer les outputs :
	- `aws_vpn_tunnel1_address` : IP publique du tunnel côté AWS
	- `aws_vpn_tunnel1_vgw_inside_address` : IP BGP côté AWS
	- `aws_vpn_tunnel1_cgw_inside_address` : IP BGP côté Scaleway
	- `aws_vpn_tunnel1_preshared_key` : PSK généré (si non surchargé)

## 5. Configurer le Customer Gateway et la connexion côté Scaleway

- Dans `main.tf` côté Scaleway, renseigner :
	- `cgw_ip` = `aws_vpn_tunnel1_address`
	- `private_ip` = `aws_vpn_tunnel1_cgw_inside_address/30`
	- `peer_private_ip` = `aws_vpn_tunnel1_vgw_inside_address/30`

- Appliquer la configuration :
```sh
terraform apply
```

## 6. Récupérer le PSK Scaleway

- Après l'apply Scaleway, récupérer le PSK :
```sh
terraform output scw_vpn_psk
```

## 7. Synchroniser le PSK côté AWS

- Passer la valeur du PSK Scaleway à la variable `scw_vpn_psk` côté AWS (via un fichier `.tfvars` ou variable d'environnement).
- Relancer :
```sh
terraform apply
```

## 8. Vérification

- Vérifier l'état du tunnel VPN dans les consoles AWS et Scaleway.
- Tester la connectivité réseau entre les deux VPC.

---

**Remarques :**
- Pour chaque tunnel, répéter les étapes avec les valeurs du second tunnel.
- Adapter les CIDR, ASN et paramètres selon votre architecture.
- Pour automatiser la synchronisation des outputs entre les deux stacks, utiliser le provider `terraform_remote_state`.
