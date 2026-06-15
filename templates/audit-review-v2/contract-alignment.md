# Contract Alignment Audit

```text
Audit alignment among API/protobuf contracts, database schema, models,
serialization, time units, enum semantics, and client-visible behavior.

Starting points to customize:
- Public API/protobuf/openapi definitions: {{api_contract_paths}}
- Schema and migrations: {{schema_paths}}
- Model/repository code: {{model_paths}}
- Serialization and DTO conversion: {{dto_paths}}

Check:
- Field unit drift: cents vs dollars, seconds vs milliseconds, timezone, count
  vs amount, enum values, or boolean meaning.
- API documentation/comment differs from implementation.
- Schema column type/nullability/default differs from model assumptions.
- Migration exists without code support or code references a missing column.
- Backward-incompatible enum, field rename, default change, or required-field
  change.
- Pagination, sorting, filtering, or status semantics differ across endpoints.
- Generated code is stale relative to source contract.

For each finding, include the three-way comparison where relevant
(contract/schema/code), concrete mismatch, affected caller, compatibility
impact, and minimal repair direction.
```
