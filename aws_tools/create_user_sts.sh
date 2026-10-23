#!/usr/bin/env bash
# Run using existing administrator credentials.
# Fresh setup only: the user and role must not already exist.
set -euo pipefail
export AWS_PAGER=""

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
USER_NAME="sts-admin-user"
ROLE_NAME="AssumableAdminRole"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

aws iam create-user --user-name "$USER_NAME" >/dev/null

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[{
      \"Effect\":\"Allow\",
      \"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:root\"},
      \"Action\":\"sts:AssumeRole\",
      \"Condition\":{\"ArnEquals\":{\"aws:PrincipalArn\":\"arn:aws:iam::${ACCOUNT_ID}:user/${USER_NAME}\"}}
    }]
  }" >/dev/null

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam put-user-policy \
  --user-name "$USER_NAME" \
  --policy-name AllowAssumeAdminRole \
  --policy-document "{
    \"Version\":\"2012-10-17\",
    \"Statement\":[{
      \"Effect\":\"Allow\",
      \"Action\":\"sts:AssumeRole\",
      \"Resource\":\"${ROLE_ARN}\"
    }]
  }"

KEYS=$(aws iam create-access-key \
  --user-name "$USER_NAME" \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text)

read -r ACCESS_KEY_ID SECRET_ACCESS_KEY <<< "$KEYS"

aws configure set aws_access_key_id "$ACCESS_KEY_ID" \
  --profile "$USER_NAME"

aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY" \
  --profile "$USER_NAME"

aws configure set aws_session_token "" --profile "$USER_NAME"
aws configure set aws_security_token "" --profile "$USER_NAME"

unset KEYS ACCESS_KEY_ID SECRET_ACCESS_KEY

sleep 10

aws sts get-caller-identity --profile "$USER_NAME" >/dev/null

CREDENTIALS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name admin-session \
  --profile "$USER_NAME" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

read -r ACCESS_KEY SECRET TOKEN <<< "$CREDENTIALS"

cat <<'COW'
 __________________________________
< Moo! ACCESS KEY, SECRET and TOKEN! >
 ----------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
COW

printf '\nACCESS KEY: %s\nSECRET:     %s\nTOKEN:      %s\n' \
  "$ACCESS_KEY" "$SECRET" "$TOKEN"

unset CREDENTIALS ACCESS_KEY SECRET TOKEN

