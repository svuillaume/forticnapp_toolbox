#!/usr/bin/env bash
# Run with separate administrator credentials.
set -euo pipefail

USER_NAME="sts-admin-user"
ROLE_NAME="AssumableAdminRole"

KEY_IDS=$(aws iam list-access-keys \
  --user-name "$USER_NAME" \
  --query 'AccessKeyMetadata[].AccessKeyId' \
  --output text)

for KEY_ID in $KEY_IDS; do
  aws iam delete-access-key \
    --user-name "$USER_NAME" \
    --access-key-id "$KEY_ID"
done

aws iam delete-user-policy \
  --user-name "$USER_NAME" \
  --policy-name AllowAssumeAdminRole

aws iam delete-user --user-name "$USER_NAME"

aws iam detach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam delete-role --role-name "$ROLE_NAME"
