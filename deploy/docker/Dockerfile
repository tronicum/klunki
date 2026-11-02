# Klunki relay as a small container image (KLD-114, prepared, not yet built
# by the project: the first real build needs the maintainer's OK).
#
# Build from the REPOSITORY ROOT (the relay needs packages/klunki_net and
# packages/klunki_engine):
#
#   docker build -f deploy/docker/Dockerfile -t klunki-relay .
#
# Run (club codes in ./data/codes.txt, see README.md):
#
#   docker run --rm -p 4749:4749 -v "$PWD/data:/data:ro" klunki-relay
#
# The image contains the AOT-compiled `klunki` CLI and nothing else: no
# shell, no package manager, no web assets (mount a built PWA and add
# `--web /web` to serve it).

# ---------------------------------------------------------------- build
# Same Dart as the repo's toolchain (AGENTS.md: Dart 3.13.7). Pin the digest
# too once the image has been pulled for the first time
# (`docker inspect --format '{{index .RepoDigests 0}}' dart:3.13.7`).
FROM dart:3.13.7 AS build

WORKDIR /src
# Only what the relay needs (Dockerfile.dockerignore keeps the rest out).
COPY packages/klunki_engine/ packages/klunki_engine/
COPY packages/klunki_net/ packages/klunki_net/
COPY deploy/docker/relay/ deploy/docker/relay/

WORKDIR /src/deploy/docker/relay
# Path dependencies only: resolves without downloading anything.
RUN mkdir -p /out/data \
 && dart pub get --offline \
 && dart compile exe bin/relay.dart -o /out/klunki

# -------------------------------------------------------------- runtime
# `scratch` plus the few files Dart's AOT executables need at run time
# (glibc, the dynamic loader and a few config files), which the official
# Dart image keeps ready in /runtime/ for exactly this purpose.
FROM scratch

COPY --from=build /runtime/ /
COPY --from=build /out/klunki /app/klunki
# An empty /data owned by the runtime user, for the codes file volume.
COPY --from=build --chown=65532:65532 /out/data /data

# Not root: a fixed numeric user (there is no /etc/passwd entry to name).
USER 65532:65532

EXPOSE 4749

# The relay answers a plain GET /relay with "426 Upgrade Required"; the
# healthcheck sub-command checks exactly that (no club code, no room).
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["/app/klunki", "healthcheck", "4749"]

ENTRYPOINT ["/app/klunki"]
# Club codes are required by default: the relay does not start without a
# readable /data/codes.txt, and admits nobody while it holds no code. For an
# open relay (no codes; only sensible on a private network) run the image
# with the command: relay --port 4749
CMD ["relay", "--port", "4749", "--codes", "/data/codes.txt"]
