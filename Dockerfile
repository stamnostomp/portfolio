# Stage 1: build the site with the Nix flake
FROM nixos/nix:latest AS build

WORKDIR /app
COPY . .

RUN nix --extra-experimental-features "nix-command flakes" build . \
    && cp -rL result /output

# Stage 2: serve the static site with nginx
FROM nginx:alpine

COPY --from=build /output/ /usr/share/nginx/html/

EXPOSE 80
