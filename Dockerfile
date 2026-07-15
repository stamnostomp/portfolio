# Stage 1: build the site with the Nix flake
FROM nixos/nix:latest AS build

WORKDIR /app
COPY . .

RUN nix --extra-experimental-features "nix-command flakes" build . \
    && cp -rL result /output

# Stage 2: serve the static site with nginx
FROM nginx:alpine

COPY --from=build /output/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Nix store files carry epoch (1970) mtimes, so nginx's Last-Modified/ETag
# never change between builds and browsers cache the old elm.js forever.
RUN find /usr/share/nginx/html -exec touch {} +

EXPOSE 80
