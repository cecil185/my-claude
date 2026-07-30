# API Doc — Examples

> **Word limit: minimum to make each endpoint actionable.** No prose about what REST is.

---

## Structure

```
# API Name

> Summary — what this API does, auth model, base URL. See [Endpoints] for the full list.

## Authentication
## Endpoints
## Error Codes
## Examples
```

---

## Summary callout rules

- What the API does (one clause)
- Auth method
- Base URL
- Pointer to Endpoints section

### Example
```
> Sportlogiq game data API — returns per-game physical metrics for hockey players. Bearer token auth. Base URL: `https://api.sportlogiq.com/v1`. See [Endpoints] for available resources.
```

---

## Endpoints section

Table format: method + path + description. Parameters and response inline below each entry.

```
### GET /games/{game_id}/metrics

Returns physical metrics for all players in a game.

| Param | Type | Required | Description |
|---|---|---|---|
| game_id | string | yes | Sportlogiq game identifier |
| since | ISO 8601 | no | Only return events after this timestamp |

**Response:** Array of player metric objects. See [Examples].
```

---

## Error Codes section

Table only — no prose:

```
| Code | Meaning | Action |
|---|---|---|
| 401 | Token expired or invalid | Re-authenticate |
| 404 | Game not found | Verify game_id exists in Sportlogiq |
| 429 | Rate limited | Back off 60s and retry |
```

---

## Never
- Explaining what HTTP methods are
- Prose descriptions of what JSON is
- Endpoint examples without a real response body
