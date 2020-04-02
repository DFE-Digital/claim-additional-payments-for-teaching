# Secrets

## How to view or change secrets

Each environment has its own Azure key vault in a separate resource group to the
main app. The key vaults are behind a firewall and to access them you will need
to add your IP address to the allow list.

1. If you’re working in the `test` and `production` environments, first elevate
   your privileges using a
   [PIM request](priviliged-identity-management-requests.md).

2. Navigate to the key vault in the [Azure Portal](https://portal.azure.com):

   - `development` – `s118d01-secrets-kv`
   - `test` – `s118t01-secrets-kv`
   - `production` – `s118p01-secrets-kv`

3. Go to “Firewalls and virtual networks” under Networking.

4. Add your IP address under Firewall and click Save.

5. In the key vault, navigate to Secrets to view or change the secrets.

6. Delete your IP address after you have finished – it will also be
   automatically deleted after the next deploy.
