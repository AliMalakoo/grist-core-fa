#!/usr/bin/env bash
# Build a Docker image of Grist with the Persian layer, using grist-core's OWN Dockerfile.
# Nothing here re-implements the image: we merge overlay/ onto a grist-core checkout and hand that
# directory to docker. So whatever upstream's Dockerfile does (multi-stage node build, python3.11
# for formulas, the gvisor sandbox, the /persist layout, EXPOSE 8484) is what you get -- plus
# Jalali dates, RTL, and the fa catalogue.
#
#   bin/docker-build.sh                 # the upstream version pinned in UPSTREAM.lock
#   bin/docker-build.sh v1.7.30         # any tag/branch/sha of upstream
#   IMAGE=myname/grist-fa:1.0 bin/docker-build.sh
#
# Needs docker, ~4 GB free RAM for the build (tsc is the memory hog), and a few GB of disk. The
# first build downloads the world; later ones reuse the docker layer cache.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

IMAGE="${IMAGE:-grist-core-fa:latest}"
REF="${1:-}"

command -v docker >/dev/null 2>&1 || die "docker is not installed or not on PATH. If you will build the image elsewhere, run bin/checkout.sh there instead."
docker info >/dev/null 2>&1 || die "cannot talk to the docker daemon (is it running? can this user use it without sudo?)"

# 1) A grist-core tree with the Persian layer applied.
if [ -n "$REF" ]; then
  say "merging the Persian layer onto $REF"
  "$REPO_ROOT/bin/update.sh" "$REF"
elif [ ! -f "$WORK_DIR/Dockerfile" ]; then
  say "creating the merged tree in $WORK_DIR"
  "$REPO_ROOT/bin/checkout.sh"
else
  say "reusing the existing tree at $WORK_DIR (pass an upstream ref to rebuild it)"
  "$REPO_ROOT/bin/verify.sh" "$WORK_DIR" strict || warn "the tree differs from overlay/; pass a ref to rebuild it"
fi
[ -f "$WORK_DIR/Dockerfile" ] || die "$WORK_DIR has no Dockerfile -- that is the file we build from"

# 2) The `ext` build-context. grist-core's Dockerfile starts with "FROM scratch AS ext" and then
#    "COPY --from=ext / /grist/ext"; upstream's own .github/workflows/docker.yml always passes
#    `build-contexts: ext=ext`, and for the open-source image it first does `mkdir ext && touch
#    ext/dummy`, with the comment "grist-oss does not bundle ext/ but the `ext=ext` build-context
#    requires it". Copying an empty scratch stage instead is how builds die on the very first COPY,
#    so do exactly what upstream does. Result: a community-edition image, i.e. gristlabs/grist-oss
#    equivalent -- which is all grist-core is, and all our Persian layer needs.
mkdir -p "$WORK_DIR/ext"
if [ -z "$(ls -A "$WORK_DIR/ext" 2>/dev/null)" ]; then
  touch "$WORK_DIR/ext/dummy"
  say "created an empty ext/ (community edition; no full-edition extensions in this image)"
else
  say "ext/ already has content -- it will be baked into the image"
fi
extra=()
if docker build --help 2>&1 | grep -q -- '--build-context'; then
  extra=(--build-context "ext=$WORK_DIR/ext" --progress plain)
else
  warn "this docker build has no --build-context (BuildKit is off?); relying on the Dockerfile's stub stage"
fi

# 3) Say what is going into the image, so the build is not a black box.
say "the 19 Persian files, as found in the build context:"
missing=0
for f in $(list_of "$FILES_LIST"); do
  if [ -f "$WORK_DIR/$f" ]; then printf '    %s\n' "$f"; else printf '    MISSING  %s\n' "$f"; missing=$((missing + 1)); fi
done
[ "$missing" -eq 0 ] || die "$missing of the Persian files are missing from $WORK_DIR -- re-run bin/checkout.sh"

# 4) Build. Both the context and the Dockerfile are the merged grist-core directory.
say "docker build -t $IMAGE  (the slow part: full node build + python sandbox)"
docker build -t "$IMAGE" ${extra[@]+"${extra[@]}"} "$WORK_DIR"

cat <<EOF

Built: $IMAGE

Run it:
    docker run -d --name grist-fa -p 8484:8484 \\
      -v grist-fa-persist:/persist \\
      -e GRIST_SESSION_SECRET="$(head -c 24 /dev/urandom | base64 | tr -d '/+=')" \\
      -e GRIST_BOOT_KEY="$(head -c 12 /dev/urandom | base64 | tr -d '/+=')" \\
      $IMAGE
    # then open http://localhost:8484  (or use docker compose, see docker-compose.yml)

GRIST_BOOT_KEY is the password for the /admin panel; if you leave it out, Grist prints a random one
into the container log ("BOOT KEY: ..."). Your documents live in the named volume
grist-fa-persist, so the container can be deleted and recreated freely.

After updating this repo:   git pull && bin/docker-build.sh && docker compose up -d
EOF
