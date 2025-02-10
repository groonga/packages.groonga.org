# README

This repository is for packages.groonga.org.

## How to deploy

    % sudo apt install -V ansible
    % rake deploy

## How to test

    % sudo apt install -V vagrant ansible
    % bundle install
    % rake

## How to add a new auto signing target

1. Create a new team for release in the target organization
   * e.g. Create `pgroonga-release` at
     https://github.com/orgs/pgroonga/new-team for PGroonga
2. Add `groonga-release` to the added team
3. Add the added team to target project's collaborators with "Write"
   role
   * e.g. Add the added team to pgroonga/pgroonga with "Write" role at
     https://github.com/pgroonga/pgroonga/settings/access
4. Setup personal access tokens for the target organization
   * e.g. https://github.com/organizations/pgroonga/settings/personal-access-tokens-onboarding
     * "Allow access via fine-grained personal access tokens"
     * "Require administrator approval"
     * "Restrict access via personal access tokens (classic)"
5. Login to GitHub as `groonga-release`
6. Create a new fine-grained personal access token at
   https://github.com/settings/personal-access-tokens
   * Token name: Project name: e.g. PGroonga
   * Resource owner: Target organization: e.g. pgroonga
   * Repository access: Only select repositories: e.g. pgroonga/pgroonga
   * Repository permissions:
     * Metadata: Read-only
     * Contents: Read and write: We need to upload signed artifacts to
       GitHub Releases
   * You must copy the generated token
7. Add the generated token to `ansible/vars/private.yml`
   * e.g. Run `rake private.yml` and add
     `packages.github_token.pgroonga` with the copied generated token
8. Approve the created fine-grained personal access token in the
   target organization
   * e.g. https://github.com/organizations/pgroonga/settings/personal-access-token-requests
9. Add `ansible/templates/home/packages/.env.#{PROJECT}.jinja` with
   `GH_TOKEN={{ packages.github_token.#{PROJECT} }}`
   * e.g. `GH_TOKEN={{ packages.github_token.pgroonga }}`
10. Add the added `.env.#{PROJECT}.jinja` to `ansible/playbook.yml`
11. Deploy by `rake deploy`
12. Add a webhook to the target project
    * e.g. https://github.com/pgroonga/pgroonga/settings/hooks
      * Payload URL: https://packages.groonga.org/webhook
      * Content type: `application/json`
      * Secret: See `packages.webhook.secret_token` in `ansible-vault
        view --vault-password-file=ansible/password
        ansible/vars/private.yml`
      * Which events would you like to trigger this webhook?:
        * `Let me select individual events.`
        * `Releases`

## License

* Codes in `ansible/files/home/`: GPLv3+
* Others: CC0-1.0

See `COPYING` for GPLv3+ and `LICENSE` for CC0-1.0.
