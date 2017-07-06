#!/bin/bash -ex

set -a

: ${RUBY_VERSION=2.2}
sed "s/\${RUBY_VERSION}/$RUBY_VERSION/" Dockerfile > Dockerfile.$RUBY_VERSION
docker-compose build --pull

function finish {
  docker-compose down
}
trap finish EXIT

docker-compose pull pg possum 
POSSUM_DATA_KEY="$(docker-compose run -T --no-deps possum data-key generate)"

docker-compose up -d possum

docker-compose run test ci/wait_for_server.sh

CONJUR_AUTHN_API_KEY=$(docker-compose exec -T possum rails r "print Credentials['cucumber:user:admin'].api_key")

docker-compose run test "$@"

