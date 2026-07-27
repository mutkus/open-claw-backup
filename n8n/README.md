# n8n workflow export

This folder is where the actual n8n workflow JSON files live once you export
them from your own instance — they aren't included in this template because
they contain your credential *references* (names/IDs) and folder IDs, which
are specific to your n8n instance and Google Drive account.

## How to export

1. Open the workflow in n8n.
2. Click the **`...`** menu (top right) → **Download**.
3. Save the file here as `openclaw-backup.json`.
4. Repeat for the error-handling workflow → save as `openclaw-backup-error-handler.json`.

Exported workflow JSON never contains credential *secrets* (tokens, passwords,
private keys) — only credential names/IDs and node parameters — so it's safe
to commit, but double-check before pushing if you've hardcoded anything
(folder IDs, chat IDs) that you'd rather keep private.

## Workflow structure (for reference)

**Main workflow — `openclaw-backup`**

| # | Node | Type | Purpose |
|---|------|------|---------|
| 1 | Schedule Trigger | Schedule Trigger | Runs the backup on a cron schedule |
| 2 | Sunucu da Backup Script Çalıştırma | SSH → Command | Runs `openclaw-backup.sh` via scoped `sudo -n` |
| 3 | Backup'ı İndirme | SSH → File → Download | Pulls the archive from the server into n8n |
| 4 | Google Drive Upload | Google Drive → File → Upload | Uploads the archive to a dedicated Drive folder |
| 5 | Sunucudan Silme | SSH → Command | Deletes the local `/tmp` copy on the OpenClaw server |
| 6 | Drive'da Dosyaları Bulma | Google Drive → File/Folder → Search | Lists all backups in the target Drive folder |
| 7 | Eski Dosyayı Tespit Etme | Code | Sorts by `createdTime`; flags the oldest file if count > 2 |
| 8 | Eski Dosyayı Silme | Google Drive → File → Delete | Deletes the flagged file (retention = 2 backups) |
| 9 | Send a text message | Telegram | Sends a success notification |

Nodes 6–8 and node 9 both branch off node 5 in parallel, so the Telegram
success message always fires once the upload and cleanup succeed —
independent of whether a retention delete actually happened that run.

**Error workflow — `openclaw-backup-error-handler`**

| # | Node | Type | Purpose |
|---|------|------|---------|
| 1 | Error Trigger | Error Trigger | Fires when the main workflow fails on any node |
| 2 | Send a text message | Telegram | Sends a failure notification with the error details |

Linked to the main workflow via **Settings → Error Workflow**.
