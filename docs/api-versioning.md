# API Versioning Strategy for F*ckDebt

## Why Version the API?
Versioning ensures that older API clients **continue working** even when breaking changes are introduced.

## Versioning Approach
F*ckDebt follows **URL-based versioning**:
```sh
https://api.fckdebt.com/v1/debts/list
```
This makes it easy for clients to **use specific versions** without affecting others.

## Versioning Policy
- **Minor Changes (Backwards Compatible)**
  - Adding new endpoints or optional parameters **does NOT require a new version**.
  - Example: Adding `/v1/debts/export` without breaking `/v1/debts/list`.

- **Major Changes (Breaking)**
  - When an endpoint **removes or changes** a required parameter, a **new version (`v2`) is created**.
  - Example:
    ```
    GET /v1/debts/list → Returns debts as an array
    GET /v2/debts/list → Returns debts as a paginated object
    ```

## Version Naming Convention
- **Major versions only (`v1`, `v2`, `v3`...)**.
- Minor versions are **not** explicitly named (e.g., `/v1.1/debts/list` is NOT used).
- 
## Deprecation Policy
When a new API version is released:
1. The **older version remains active** for **at least 6 months**.
2. Deprecation notices are **returned in API responses**:
   ```json
   {
     "warning": "API v1 will be deprecated on 2025-12-31. Please switch to v2."
   }
   ```
3. Once deprecated, the **version is removed** from the documentation.

## Migration Guidelines
To migrate from an old version:
1. **Check `/docs/api.md`** for the latest changes.
2. **Modify API calls** to match new parameters.
3. **Test endpoints** before updating production.

## Best Practices
- Always **default to the latest stable version** (`v1`).
- Use **feature flags** to test upcoming API versions.

## References
- [F*ckDebt API Documentation](/docs/api.md)
- [REST API Best Practices](https://restfulapi.net/versioning/)