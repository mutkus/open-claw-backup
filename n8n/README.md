# n8n workflow export

## `openclaw-backup.json`

The main backup workflow **is included** in this folder as a redacted
template — credential IDs, the Google Drive folder ID, the Telegram chat
ID, and other instance-specific identifiers have been replaced with
placeholders so it's safe to publish.

### Using it

1. In n8n: **Workflows → Import from File** → select `openclaw-backup.json`.
2. Re-select (or create) each credential the import prompts you for:
   - SSH credential on the three SSH nodes
   - Google Drive OAuth2 credential on the three Google Drive nodes
   - Telegram credential on the "Send a text message" node

   n8n will flag these automatically since the placeholder credential IDs
   won't match anything in your instance.
3. Manually replace these two node parameter values — n8n won't prompt for
   these, they're just placeholder text sitting in the field:
   - **Google Drive Upload** node → `Parent Folder` → your real Drive folder ID
   - **Send a text message** (Telegram) node → `Chat ID` → your real chat ID
4. The workflow imports as **inactive** on purpose — review the Schedule
   Trigger and everything else, then activate it yourself.

You don't need to touch `versionId`, the workflow `id`, or `webhookId` —
n8n regenerates these on import.

## `openclaw-backup-error-handler.json`

The error-handling workflow (Error Trigger → Telegram) **is included** in
this folder as a redacted template, same as the main workflow — the
Telegram chat ID, credential ID, `versionId`, `webhookId`, workflow `id`,
and `meta.instanceId` have all been replaced with placeholders or removed.

### Using it

1. In n8n: **Workflows → Import from File** → select
   `openclaw-backup-error-handler.json`.
2. Re-select (or create) the Telegram credential on the "Send a text
   message1" node — n8n will prompt you since the placeholder credential ID
   won't match anything in your instance.
3. Manually replace the **Chat ID** field with your real Telegram chat ID —
   this is a plain parameter value, so n8n won't prompt for it on its own.
4. It imports as **inactive** — activate it once you've checked it over.
5. Go to your main **`openclaw-backup`** workflow → **Settings** → **Error
   Workflow** → select this workflow, so failures anywhere in the main
   chain reach it.

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
