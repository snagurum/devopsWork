#! /bin/sh

# helm install db-backup-cronjobs dysnix/raw -f cronjob.yaml --version 0.3.1 -n ahdev

set -eo pipefail

if [ "**${S3_ACCESS_KEY_ID}**" = "****" ]; then
  echo "You need to set the S3_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "**${S3_SECRET_ACCESS_KEY}**" = "****" ]; then
  echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "**${S3_BUCKET}**" = "****" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "**${POSTGRES_DATABASE}**" = "****" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "**${POSTGRES_HOST}**" = "****" ]; then
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
fi

if [ "**${POSTGRES_USER}**" = "****" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable"
  exit 1
fi

POSTGRES_PORT=${POSTGRES_PORT:- 5432}
S3_RETENTION_PERIOD=${RETENTION_PERIOD:- 21}
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -d $POSTGRES_DATABASE -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

if [ -z ${S3_PREFIX+x} ]; then
  S3_PREFIX="/"
else
  cur_date=$(date "+%Y-%m-%d")
  S3_PREFIX="/${S3_PREFIX}/${cur_date}/"
fi

SRC_FILE=${POSTGRES_DATABASE}.sql.gz
DEST_FILE=${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz

echo "1. Waiting for network initialization"
while ! nc -z $POSTGRES_HOST $POSTGRES_PORT; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done


echo "2. Creating dump of ${POSTGRES_DATABASE} databases from ${POSTGRES_HOST}..."
PGPASSWORD=$POSTGRES_PASSWORD pg_dump $POSTGRES_HOST_OPTS | gzip > $SRC_FILE

echo "3. Encrypting dump file"
if [ "**${ENCRYPTION_PASSWORD}**" != "****" ]; then
  echo "Encrypting ${SRC_FILE}"
  openssl enc -aes-256-cbc -in $SRC_FILE -out ${SRC_FILE}.enc -k $ENCRYPTION_PASSWORD
  if [ $? != 0 ]; then
    >&2 echo "Error encrypting ${SRC_FILE}"
  fi
  rm $SRC_FILE
  SRC_FILE="${SRC_FILE}.enc"
  DEST_FILE="${DEST_FILE}.enc"
fi

echo "4. Executing retension rules for s3 bucket"
aws s3 ls s3://${S3_BUCKET}/ --recursive | while read -r line; do
  file_date=$(echo $line | awk '{print $1}')
  file_name=$(echo $line | awk '{$1=""; $2=""; print $0}' | sed 's/^[ \t]*//')
  file_age=$(( ($(date +%s) - $(date -d "$file_date" +%s)) / 86400 ))
  
  if [ $file_age -gt $S3_RETENTION_PERIOD ]; then
    aws s3 rm "s3://my-bucket/$file_name"
    echo "Deleted: $file_name (Age: $file_age days)"
  fi
done

echo "5. Uploading dump to $S3_BUCKET"
cat $SRC_FILE | aws $AWS_ARGS s3 cp - "s3://${S3_BUCKET}${S3_PREFIX}${DEST_FILE}" || exit 2
rm -rf $SRC_FILE

echo "6. Exit"
exit 0


