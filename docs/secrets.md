# Secrets

## How to view or change secrets

Each environment has its own Azure key vault in a separate resource group to the
main app.

1. If you’re working in the `production` environment, first elevate your
   privileges using a [PIM request](priviliged-identity-management-requests.md).

2. Navigate to the key vault in the [Azure Portal](https://portal.azure.com):

   - `review` – `s189t01-capt-rv-app-kv`
   - `test` – `s189t01-capt-ts-app-kv`
   - `production` – `s189p01-capt-pd-app-kv`

3. In the key vault, navigate to Secrets to view or change the secrets.
