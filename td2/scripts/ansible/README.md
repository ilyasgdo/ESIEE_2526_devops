# Ansible AWS Scripts

## Utilisation sécurisée

### Configuration des credentials AWS

**⚠️ IMPORTANT : Ne jamais committer les clés AWS dans le code !**

Avant d'exécuter le script `run-ansible.sh`, configurez vos credentials AWS comme variables d'environnement :

```bash
# Définir les credentials AWS (remplacez par vos vraies clés)
export AWS_ACCESS_KEY_ID="your_access_key_here"
export AWS_SECRET_ACCESS_KEY="your_secret_key_here"
export AWS_DEFAULT_REGION="us-east-2"

# Exécuter le script
./run-ansible.sh
```

### Alternative : Utiliser AWS CLI configure

Vous pouvez aussi configurer AWS CLI une fois pour toutes :

```bash
aws configure
```

### Scripts disponibles

- `run-ansible.sh` : Script principal pour déployer une instance EC2
- `create_ec2_instance_playbook.yml` : Playbook Ansible pour une instance
- `create_multiple_ec2_instances_playbook.yml` : Playbook pour plusieurs instances
- `cleanup_all_resources.yml` : Playbook pour nettoyer toutes les ressources

### Bonnes pratiques de sécurité

1. **Jamais de clés hardcodées** dans le code
2. **Utiliser des variables d'environnement** ou AWS CLI configure
3. **Nettoyer les ressources** après utilisation pour éviter les coûts
4. **Utiliser des instances Free Tier** (t3.micro, t2.micro)