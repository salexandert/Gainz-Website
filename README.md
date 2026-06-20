# Gainz Website

This repository contains the public marketing site for Gainz at <https://cryptogainz.store/>.

The Gainz desktop app lives separately at <https://github.com/salexandert/Gainz>. Keeping the website in its own repository lets Netlify deploy public site updates without mixing website hosting concerns into the private offline app codebase.

## Source Of Truth

- Product documentation and walkthrough content lives in the Gainz app repository and GitHub wiki.
- This website links users to the wiki and selected guide pages.
- Website screenshots are copied from the app repository after product UI changes.
- Netlify project `gainzstore` deploys this repository's `main` branch.

## Update Flow

1. Update the Gainz app and app docs in your local Gainz app checkout.
2. Regenerate or refresh screenshots in the app repository's `docs/assets/screenshots` folder.
3. From this repository, run:

   ```powershell
   .\scripts\sync-from-app.ps1 -AppRepoPath path\to\Gainz
   ```

4. Review the website locally or with Netlify preview.
5. Commit and push this website repository.
6. Netlify deploys the public site from the tracked source.

## Website Analytics

Use privacy-preserving aggregate analytics for the public website only.

- Netlify Web Analytics is the preferred current setup because it can be enabled in Netlify project settings without adding a tracking script to this repo.
- Do not add ad pixels, remarketing tags, or broad behavioral tracking.
- Do not add any local Gainz app telemetry. The desktop app must not upload transaction history, tax evidence, audit packets, or user actions to this website.

Public GitHub Release download counts are tracked separately by the Gainz app repository workflow under `metrics/github-release-downloads/`.

## Public Data Rule

Only public website assets belong here. Do not commit Gainz saves, exports, tax files, logs, credentials, or user data.
